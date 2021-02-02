import sys
# Navigate to folder which contains ELINA.                          
sys.path.insert(0, '../ELINA/python_interface/')

import numpy as np
import re
import csv 
from elina_box import *
from elina_interval import *
from elina_abstract0 import *
from elina_manager import *
from elina_dimension import *
from elina_scalar import *
from elina_interval import *
from elina_linexpr0 import *
from elina_lincons0 import *
import ctypes
from ctypes.util import find_library
from gurobipy import *
import time
from copy import deepcopy

libc = CDLL(find_library('c'))
cstdout = c_void_p.in_dll(libc, 'stdout')

################################################################################
## Definition of neural network 
################################################################################
class layers:
    def __init__(self):
        self.layertypes = []
        self.weights = []
        self.biases = []
        self.numlayer = 0
        self.ffn_counter = 0

################################################################################
## Parsing input (network and image)
################################################################################
def parse_bias(text):
    """Parses the bias of a NN and returns a 1d np.array of doubles with
    the biases in shape (v.size,) """
    if len(text) < 1 or text[0] != '[':
        raise Exception("expected '['")
    if text[-1] != ']':
        raise Exception("expected ']'")
    v = np.array([*map(lambda x: np.double(x.strip()), text[1:-1].split(','))])
    #return v.reshape((v.size,1))
    return v

def parse_vector(text):
    """Parses the a 1d list of values (e.g. NN bias) and returns them as
    1d np.array in shape (v.size, 1)"""
    if len(text) < 1 or text[0] != '[':
        raise Exception("expected '['")
    if text[-1] != ']':
        raise Exception("expected ']'")
    v = np.array([*map(lambda x: np.double(x.strip()), text[1:-1].split(','))])
    return v.reshape((v.size,1))
    #return v

def balanced_split(text):
    """Slices a 2d text file containing [0.10, ... ,0.2],[0.43, ... ]
    into a list with elements
    '[0.10, ... ,0.2]'
    '[0.43, ... ]'
    """
    i = 0
    bal = 0
    start = 0
    result = []
    while i < len(text):
        if text[i] == '[':
            bal += 1
        elif text[i] == ']':
            bal -= 1
        elif text[i] == ',' and bal == 0:
            result.append(text[start:i])
            start = i+1
        i += 1
    if start < i:
        result.append(text[start:i])
    return result

def parse_matrix(text):
    """Parses a 2d weight matrix for a NN and returns it as 2d np.array
    of shape (n_rows, n_cols)"""
    i = 0
    if len(text) < 1 or text[0] != '[':
        raise Exception("expected '['")
    if text[-1] != ']':
        raise Exception("expected ']'")
    return np.array([*map(lambda x: parse_vector(x.strip()).flatten(), balanced_split(text[1:-1]))])

def parse_net(text):
    """Parses and reads in a NN into a layers object. Returns layers object"""
    lines = [*filter(lambda x: len(x) != 0, text.split('\n'))]
    i = 0
    res = layers()
    while i < len(lines):
        if lines[i] in ['ReLU', 'Affine']:
            W = parse_matrix(lines[i+1])
            b = parse_bias(lines[i+2])
            res.layertypes.append(lines[i])
            res.weights.append(W)
            res.biases.append(b)
            res.numlayer+= 1
            i += 3
        else:
            raise Exception('parse error: '+lines[i])
    return res
   
def parse_spec(text):
    """Parses mnist image file and reads it into two 1d np.array (intervals of
    low, high) via creating a dummy file. Returns two 1d np.arrays
    one with lower and one with higher values of intervals within which
    given pixel values can fall. Shapes are (n_size, ).
    In this default version only low is used further (see __name__ == main part)"""
    text = text.replace("[", "")
    text = text.replace("]", "")
    with open('dummy', 'w') as my_file:
        my_file.write(text)
    data = np.genfromtxt('dummy', delimiter=',',dtype=np.double)
    low = np.copy(data[:,0])
    high = np.copy(data[:,1])
    return low,high

def print_weights(nn, k):
    assert k < nn.numlayer
    print('Weights:', nn.weights[k])
    print('Bias:', nn.biases[k])

################################################################################
## Image operations
################################################################################

def get_perturbed_image(x, epsilon):
    """Performs the epsilon perturbation on an image contained in x.
    Lower pixel value intervall bound is lowered by epsilon, higher bound is
    increased by epsilon. If hard pixel intervall limits [0,1] are surpassed the
    values for lower/upper bound are set to 0/1.
    In this default version x is always low from parse_spec (see __name__ == main part)"""
    image = x[1:len(x)]
    num_pixels = len(image)
    LB_N0 = image - epsilon
    UB_N0 = image + epsilon
     
    for i in range(num_pixels):
        if(LB_N0[i] < 0):
            LB_N0[i] = 0
        if(UB_N0[i] > 1):
            UB_N0[i] = 1
    return LB_N0, UB_N0
    
################################################################################
## Robustness analysis
################################################################################
def take_min_max(xl, xu, w_row, bias):
    '''Depending on the values of the weights in a row of the weightmatrix
    (w_row) choose the correct interview boundary to capture the maximal
    possible value. I.e. for negative weights the ordering of the interval borders
    has to be switched. This method is called in analyze_layer_box.
    @param[in]   xl         lower bounds before [Nx1]
    @param[in]   xu         upper bounds before [Nx1]
    @param[in]   w_row      one row of the weight matrix [1xN]
    @param[in]   bias       bias value for the i-th coordinate, i in [1,M]  [1x1]
    @param[out]  xl_next_i  new lower interval bound for the i-th coordinate, i in [1,M]
    @param[out]  xu_next_i  new upper interval bound for the i-th coordinate, i in [1,M]
    '''
    xl_next_i = bias
    xu_next_i = bias

    for j, weight in enumerate(w_row):
        if weight >=0:
            xl_next_i += weight * xl[j]
            xu_next_i += weight * xu[j]
        else:
            xl_next_i += weight * xu[j]
            xu_next_i += weight * xl[j]
    return xl_next_i, xu_next_i


def analyze_layer_box(weights, biases, layer_type, xl, xu):
    ''' Propagate interval constraint through one layer of neural network
    and output lower and upper bound after layer's activation function using 
    interval propagation, i.e. transform lower and upper bound independently
    from each other.  
    @param[in]  weights     layer weights [MxN].
    @param[in]  biases      layer biases. [Mx1].
    @param[in]  layer_type  type of activation function ['ReLU','Affine'].
    @param[in]  xl          lower bounds before [Nx1].
    @param[in]  xu          upper bounds before [Nx1].
    @param[out] xl_next     lower bounds after propagation [Mx1]. 
    @param[out] xu_next     upper bounds after propagation [Mx1]. '''
    assert(layer_type in ['ReLU','Affine'])
    assert(xl.shape == xu.shape)
    assert(xl.shape[0] == weights.shape[1])
    assert(weights.shape[0] == biases.shape[0])
    
    # Propagation. 
    xl_next = np.zeros_like(biases)
    xu_next = np.zeros_like(biases)

    for i, w_row in enumerate(weights):
        xl_next[i], xu_next[i] = take_min_max(xl, xu, w_row, biases[i])
        #if xl_next[i] < 0:
        #    print(i, 'Finally < 0')

    if layer_type == 'ReLU':
        xl_next[xl_next<0] = 0
        xu_next[xu_next<0] = 0
    return xl_next, xu_next

def classify(nn, xl, xu):
    ''' Classify the network's output based on lower and upper activation 
    bounds of every output class. We search for the class i which's activation
    is greater than the activations of any other class, i.e. if the network
    outputs the class i the lower bound of i has to be larger than every other
    classes j upper activation bound.
    @param[in]  xl      lower activation bound at nn's output layer [Mx1]. 
    @param[in]  xu      upper activation bound at nn's output layer [Mx1]. '''
    assert (xl.shape == xu.shape)
    # feed forward pass through the network
    for k in range(nn.numlayer):
        weights = np.array(nn.weights[k])
        biases = np.array(nn.biases[k])
        xl = np.matmul(weights, xl) + biases
        if nn.layertypes[k] == 'ReLU':
            xl[xl < 0] = 0

    return np.argmax(xl)


def prove(xl, xu, label):
    ''' Robustness can be verified iff the lower bound of the labeled classes
    activation i is larger than the upper activation bounds of every other 
    classes activation j.
    @param[in]  xl      lower activation bound at nn's output layer [Mx1]. 
    @param[in]  xu      upper activation bound at nn's output layer [Mx1]. 
    @param[in]  label   class label to prove robustness for (int). '''
    assert(xl.shape == xu.shape)
    assert(label < xl.size)
    predicted_label = -1
    verified_flag = True
    output_size = xl.size
    i_lower = xl[label]
    for j in range(output_size):
        if(j!=label):
            j_upper = xu[j]
            if(i_lower <= j_upper):
                predicted_label = label
                verified_flag = False
                break 
    return predicted_label, verified_flag


def print_lower_upper(xl,xu):
    '''Function to print lowre and upper bounds in interval notation to console.'''
    for lb, ub in zip(xl, xu):
        print('[%.2f,\t %.2f]' % (lb, ub))

################################################################################
## Preliminary definition of interval object:
################################################################################

class interval_object:
    """Interval object to save the results of a box pass through the network
    Logits are saved in logit_intervals dictionary (they are needed to compute slope and intercept in full
    zonotope analysis)
    ReLU of logits are saved in intervals dictionary
    For the naming convention checkout the naming file."""
    def __init__(self, xl, xu):
        self.xl_in = xl
        self.xu_in = xu
        self.numlayer = 0
        self.intervals = {
            'xl_0': xl,
            'xu_0': xu
        }
        self.logit_intervals = {}
        self.fitted = False

    def set_logit_bounds(self, layer_k, hl, hu):
        assert self.numlayer > 0
        assert (layer_k < self.numlayer) and (layer_k >= 0)
        self.logit_intervals['hl_' + str(layer_k)] = hl
        self.logit_intervals['hu_' + str(layer_k)] = hu

    def set_bounds(self, layer_k, xl, xu):
        assert self.numlayer > 0
        assert (layer_k <= self.numlayer) and (layer_k >= 0)
        if not self.fitted:
            self.intervals['xl_' + str(layer_k)] = xl
            self.intervals['xu_' + str(layer_k)] = xu
        else:
            #only allow to tighten bounds
            for i in range(len(xl)):
                if xl[i] > self.intervals['xl_' + str(layer_k)][i]:
                    self.intervals['xl_' + str(layer_k)][i] = xl[i]
                if xu[i] < self.intervals['xu_' + str(layer_k)][i]:
                    self.intervals['xu_' + str(layer_k)][i] = xu[i]

    def get_bounds(self, layer_k):
        assert self.fitted
        assert(layer_k <= self.numlayer) and (layer_k >= 0)
        return self.intervals['xl_'+str(layer_k)], self.intervals['xu_'+str(layer_k)]

    def get_logit_bounds(self, layer_k):
        assert self.fitted
        assert(layer_k < self.numlayer) and (layer_k >= 0)
        return self.logit_intervals['hl_'+str(layer_k)], self.logit_intervals['hu_'+str(layer_k)]

    def get_input_bounds(self):
        # equivalent to get_bounds(layer_k = 0)
        return self.xl_in, self.xu_in

    def fit(self, nn, layer_k = 0):
        '''Fits with box from layer_k as input'''
        num_layer = nn.numlayer
        self.numlayer = num_layer
        xl = self.xl_in
        xu = self.xu_in
        num_pixels = len(xl)
        assert (num_pixels == len(xu))
        assert layer_k <= num_layer

        # Box pass through network and save intervals in self.intervals dictionary
        for k in range(layer_k, num_layer):
            layer_type = nn.layertypes[k]
            weights = np.array(nn.weights[k])
            biases = np.array(nn.biases[k])
            xl_k, xu_k = self.intervals['xl_'+str(k)], self.intervals['xu_'+str(k)]

            # Peform affine transform to get logits bounds hl_k, hu_k for kth layer
            hl_k, hu_k = analyze_layer_box(weights, biases, 'Affine', xl_k, xu_k)
            self.set_logit_bounds(k, hl_k, hu_k)

            # Perform relu operation to get new interval bounds xl_new, xu_new
            if layer_type == 'ReLU':
                xl_new = deepcopy(hl_k)
                xu_new = deepcopy(hu_k)
                xl_new[xl_new < 0] = 0
                xu_new[xu_new < 0] = 0
                self.set_bounds(k+1, xl_new, xu_new)

        self.fitted = True
        return xl_new, xu_new

    def print(self):
        for k in range(self.numlayer):
            print('===== Logits bounds layer ' + str(k) + ' ======')
            print_lower_upper(*self.get_logit_bounds(k))

            print('===== Interval bounds layer ' + str(k + 1) + ' =====')
            print_lower_upper(*self.get_bounds(k + 1))


def relu_split(model, layer_k, dim_m, h_lb, h_ub, x_lb, x_ub, h_km):
    assert h_lb <= h_ub
    assert x_lb <= x_ub
    assert x_lb >= 0

    x_km = model.addVar(vtype=GRB.CONTINUOUS, name="x_" + str(layer_k) + '_' + str(dim_m))

    if h_lb >= 0:
        C0 = model.addLConstr(x_km == h_km)
        constraints = [C0]
        flag = 1

    else:
        assert x_lb >= 0
        assert x_ub >= 0
        assert x_ub <= h_ub

        slope = x_ub / (x_ub - h_lb)
        intercept = -slope * h_lb
        assert intercept > 0

        C0 = model.addLConstr(x_km >= 0)
        C1 = model.addLConstr(x_km >= h_km)
        C2 = model.addLConstr(x_km <= slope * h_km + intercept)
        constraints = [C0, C1, C2]
        flag = 2

    return x_km, flag, constraints


def check_ub_convergence(x_ub, xu_old, abs_tol, rel_tol):
    if (xu_old - x_ub < abs_tol):
        # print('abs ub')
        return True
    if x_ub < 1e-5 or xu_old < 1e-5:
        x_ub = 0
        return True

    if (xu_old - x_ub) / xu_old < rel_tol:
        return True
    return False


def check_lb_convergence(x_lb, xl_old, abs_tol, rel_tol):
    if x_lb == 0:
        return True
    if (x_lb - xl_old  < abs_tol):
        return True
    if (x_lb - xl_old )/x_lb < rel_tol:
        return True
    return False


def tighten_bounds(model, x_km, flag, xl_old, xu_old, h_lb, h_km, constraints, abs_tol=0.005,
                   rel_tol=0.01):
    # Stable RELU case
    if len(constraints) == 1:
        model.reset()
        model.setObjective(x_km, GRB.MAXIMIZE)
        model.optimize()
        x_ub = x_km.X

        model.reset()
        model.setObjective(x_km, GRB.MINIMIZE)
        model.optimize()
        x_lb = x_km.X
        return x_lb, x_ub

    # RELU-Triangle case
    assert len(constraints) == 3
    model.reset()
    converged = False
    while not converged:
        model.setObjective(x_km, GRB.MAXIMIZE)
        model.optimize()
        x_ub = x_km.X

        if x_ub < 0.005:
            model.remove(constraints[0])
            model.remove(constraints[1])
            model.remove(constraints[2])
            model.addLConstr(x_km == 0)
            model.update()
            x_ub = 0
            return 0, 0  # In this case both lower and upper bound ==0

        else:  # slope update
            new_slope = x_ub / (x_ub - h_lb)
            new_intercept = -new_slope * h_lb
            assert new_intercept > 0
            model.remove(constraints[2])
            constraints[2] = model.addLConstr(x_km <= new_slope * h_km + new_intercept)
            model.update()

        # Convergence check
        converged = check_ub_convergence(x_ub, xu_old, abs_tol, rel_tol)
        xu_old = x_ub

    # Find lower bound
    model.reset()
    converged = False
    while not converged:
        model.setObjective(x_km, GRB.MINIMIZE)
        model.optimize()
        x_lb = x_km.X

        # Convergence check
        converged = check_lb_convergence(x_ub, xu_old, abs_tol, rel_tol)
        xu_old = x_ub

    return x_lb, x_ub


def optimize_layer_l(layer_k, nn, iobj, model, varis, label):
    '''Optimizes layer_k '''
    # Inits
    relu_bin = {'zero': 0, 'lin': 0, 'unstable': 0, 'aff': 0}

    # Get weights, biases & layertype from nn
    layer_type = nn.layertypes[layer_k - 1]
    weights = np.array(nn.weights[layer_k - 1])
    biases = np.array(nn.biases[layer_k - 1])

    # Input and output dimensions for the k-th layer
    in_dim = weights.shape[1]
    out_dim = weights.shape[0]

    # Get interval bounds from intervall object to calculate slope and intercept
    hl, hu = iobj.get_logit_bounds(layer_k - 1)
    xl, xu = iobj.get_bounds(layer_k)
    assert hl.size == out_dim
    assert xl.size == out_dim  # The x's are ReLU(h)

    for dim_m in range(out_dim):
        ws = weights[dim_m, :]  # one row of weights
        b = biases[dim_m]

        if xu[dim_m] <= 0:
            h_km = None
            varis['x_' + str(layer_k) + '_' + str(dim_m)] = 0
            relu_bin['zero'] += 1

        else:
            # Perform affine transform:  x_kn --> h_km where n iterates over input and m over output dimension
            h_km = LinExpr(b)
            for dim_n in range(in_dim):
                h_km.add(ws[dim_n] * varis['x_' + str(layer_k - 1) + '_' + str(dim_n)])

            # Activation
            if layer_type == 'ReLU':
                x_km, flag, constraints = relu_split(model, layer_k, dim_m,
                                                     h_lb=hl[dim_m], h_ub=hu[dim_m], x_lb=xl[dim_m], x_ub=xu[dim_m],
                                                     h_km=h_km)

                if flag == 1:
                    relu_bin['lin'] += 1
                elif flag == 2:
                    relu_bin['unstable'] += 1
            else:  # Affine case
                x_km = h_km
                relu_bin['aff'] += 1

            varis['x_' + str(layer_k) + '_' + str(dim_m)] = x_km

            # TIGHTEN STEP (Only for layers btw 1 & final)
            if layer_k > 1:  # For first layer (1) this would just return box.
                new_lb, new_ub = tighten_bounds(model, x_km, flag, xl[dim_m], xu[dim_m], hl[dim_m], h_km, constraints)

                # UPDATE Layer k
                iobj.intervals['xl_' + str(layer_k)][dim_m] = new_lb
                iobj.intervals['xu_' + str(layer_k)][dim_m] = new_ub

    # Final layer verification
    could_still_work = True
    if layer_k == (nn.numlayer):
        corr_label = varis['x_' + str(layer_k) + '_' + str(label)]

        for out_digit in range(10):
            if varis['x_' + str(layer_k) + '_' + str(out_digit)] is not corr_label:
                incorr_label = varis['x_' + str(layer_k) + '_' + str(out_digit)]

                model.reset()
                model.setObjective(corr_label - incorr_label, GRB.MINIMIZE)
                model.optimize()

                if corr_label.X - incorr_label.X <= 0:
                    could_still_work = False
                    break

    return relu_bin, could_still_work
    
def initialize_box(nn, LB_N0, UB_N0, label):
    iobj = interval_object(LB_N0, UB_N0)
    iobj.fit(nn)
    return iobj

def update_layer(layer_k, nn, iobj, varis, keepers_all, with_opt=True):
    '''Still todo'''
    W = nn.weights[layer_k]
    xl, xu = iobj.get_bounds(layer_k)
    keepers = get_relevant_relus(W, xu, keep_perc)
    keepers_all[layer_k] = keepers
    
def add_layer(layer_k, nn, iobj, varis, keepers_all, model, with_opt = False, keep_perc = 0.1):
    #add layer k:
    #Find relevant relus:
    W = nn.weights[layer_k]
    xl, xu = iobj.get_bounds(layer_k)
    keepers = get_relevant_relus(W, xu, keep_perc)
    keepers_all[layer_k] = keepers

    #add relevant relus:
    layer_type, weights, biases = get_layer(layer_k-1, nn)
    out_dim, in_dim = weights.shape
    hl, hu = iobj.get_logit_bounds(layer_k-1)
    xl, xu = iobj.get_bounds(layer_k)
    assert hl.size == out_dim
    assert xl.size == out_dim       # The x's are ReLU(h)

    for dim_m in range(len(xu)):
        if xu[dim_m] <= 0:
            varis['x_'+str(layer_k)+'_'+str(dim_m)] = 0 
            continue

        ws = weights[dim_m,:]  #one row of weights
        b  = biases[dim_m]

        if dim_m in keepers:
            h_km = LinExpr(b)
            for dim_n in range(in_dim):
                h_km.add( ws[dim_n] * varis['x_'+str(layer_k-1)+'_'+str(dim_n)] )

            # Activation
            if layer_type == 'ReLU':
                x_km, flag, constraints = relu_split(model, layer_k, dim_m, 
                                                  h_lb=hl[dim_m], h_ub=hu[dim_m], x_lb=xl[dim_m], x_ub=xu[dim_m], 
                                                  h_km=h_km) 
            
            if with_opt:
                out_ws = np.array(nn.weights[layer_k])[:,dim_m]
                max_out_weight = max(abs(out_ws))

                new_lb, new_ub = tighten_bounds(model, x_km, flag, xl[dim_m], xu[dim_m], hl[dim_m], h_km, constraints,
                                               abs_tol= layer_k**3/(100*max_out_weight*len(keepers)) )
                
                assert new_lb >= xl[dim_m] - 1e-7
                assert new_ub <= xu[dim_m] + 1e-7

                #UPDATE Layer k
                iobj.intervals['xl_'+str(layer_k)][dim_m] = new_lb
                iobj.intervals['xu_'+str(layer_k)][dim_m] = new_ub
                
        else:
            x_km  = model.addVar(xl[dim_m], xu[dim_m], name='x_'+str(layer_k)+'_'+str(dim_m))
        varis['x_'+str(layer_k)+'_'+str(dim_m)] = x_km 
    
def get_relevant_relus(W, xu, keep_perc=0.2):
    keepers = np.array([])
    out_dim , in_dim = W.shape
    for i in range(out_dim):
        summands = abs(W[i,:] * xu)
        max_contribution = max(summands)

        keepers = np.union1d(keepers, np.nonzero(summands >= keep_perc * max_contribution)[0])
    #print('Fraction kept:', len(keepers)/in_dim)
    return keepers.astype(int)
    
def get_layer(layer_k, nn):
    # Get weights, biases & layertype from nn
    layer_type = nn.layertypes[layer_k]
    weights = np.array(nn.weights[layer_k])
    biases = np.array(nn.biases[layer_k])
    
    return layer_type, weights, biases

################################################################################
## Function to analyze the full zonotope
################################################################################

def analyze_v1(nn, LB_N0, UB_N0, label, iobj=None):
    verified = False
    assert (LB_N0.shape == UB_N0.shape)

    # Set up variable, expression dictionarys & relu case counter
    varis = {}
    relu_bins = {}

    # First box pass
    if iobj is None:
        iobj = interval_object(LB_N0, UB_N0)
        iobj.fit(nn)
    if prove(*iobj.get_bounds(layer_k=nn.numlayer), label)[1]: return True, iobj, relu_bins, 0, label

    # set up gurobi model
    model = Model("net")
    model.setParam('OutputFlag', False)

    # Set up initial input variables & ranges for input image
    for dim_n in range(len(LB_N0)):
        x_0n = model.addVar(LB_N0[dim_n], UB_N0[dim_n], name="x_0_" + str(dim_n))
        # Add the input variables to variable dict for later access under name x_0_n
        varis['x_0_' + str(dim_n)] = x_0n

    # Add 1st layer to model
    relu_bins[1], flag = optimize_layer_l(1, nn, iobj, model, varis, label)

    for layer_k in range(2, nn.numlayer):

        relu_bins[layer_k], flag = optimize_layer_l(layer_k, nn, iobj, model, varis, label)
        iobj.fit(nn, layer_k)
        if prove(*iobj.get_bounds(layer_k=nn.numlayer), label)[1]: return True, iobj, relu_bins, layer_k, label

    relu_bins[nn.numlayer], flag = optimize_layer_l(nn.numlayer, nn, iobj, model, varis, label)
    return flag, iobj, relu_bins, layer_k, label

def analyze_v2(nn, LB_N0, UB_N0, label, iobj=None):
    varis = {}
    keepers_all = {}

    if iobj is None:
        iobj = initialize_box(nn, LB_N0, UB_N0, label)
        if prove(*iobj.get_bounds(layer_k=nn.numlayer),label)[1]: return True, iobj, 0, label

    #set up gurobi model
    model = Model("net")
    model.setParam('OutputFlag', False)

    #add layer 0
    for dim_n in range(len(LB_N0)):
        x_0n  = model.addVar(LB_N0[dim_n], UB_N0[dim_n], name="x_0_"+str(dim_n))
        # Add the input variables to variable dict for later access under name x_0_n
        varis['x_0_'+str(dim_n)] = x_0n

    #add layer 1:
    add_layer(1, nn, iobj, varis, keepers_all, model, keep_perc = 0)

    #add layer 2:
    for layer_k in range(2,nn.numlayer):
        add_layer(layer_k, nn, iobj, varis, keepers_all, model, with_opt=True, keep_perc=0)
        iobj.fit(nn,layer_k)
        if prove(*iobj.get_bounds(layer_k=nn.numlayer),label)[1]: return True, iobj, layer_k, label
        #add_layer(layer_k, nn, iobj, varis, keepers_all, with_opt=True, keep_perc=0.5)
        #iobj.fit(nn,layer_k)
        #if prove(*iobj.get_bounds(layer_k=nn.numlayer),label)[1]: return True, iobj, layer_k, label

################################################################################
## Analyze function
################################################################################
def analyze(nn, LB_N0, UB_N0, label):
    num_pixels = len(LB_N0)
    assert (num_pixels == len(UB_N0))
    num_layer = nn.numlayer
    xl = np.array(LB_N0)
    xu = np.array(UB_N0)

    # if epsilon = 0 perform classification, else do a robustness test.
    if (LB_N0[0] == UB_N0[0]):
        return classify(nn, xl, xu), False
    # Else try to prove robustness for labeled class.
    # LB and UB as vectors, Weights as matrix, bias as vector then affine
    # matrix multiplication x_next = W*x + b. Relu as x[x<0] = 0.
    elif nn.numlayer == 4:
        #print("Analyzer Box")
        iobj = initialize_box(nn, LB_N0, UB_N0, label)
        for i in range(nn.numlayer): 
            xl, xu = analyze_layer_box(nn.weights[i], nn.biases[i], nn.layertypes[i], xl, xu)
        return prove(xl, xu, label)
    elif nn.numlayer<=6 and nn.weights[2].shape[0] <= 100:
        #print("Analyzer v1")
        flag, _, _, _, _ = analyze_v1(nn, xl, xu, label)
        return _, flag
    else: 
        #print("Analyzer v2")
        flag, _, _, _ = analyze_v2(nn, xl, xu, label)
        return _, flag

################################################################################
## Main
################################################################################
if __name__ == '__main__':
    from sys import argv
    if len(argv) < 3 or len(argv) > 4:
        print('usage: python3.6 ' + argv[0] + ' net.txt spec.txt [timeout]')
        exit(1)   
    # Load network, image (lower + upper bound for every pixel and label)
    # and perturbation value epsilon from input argument. 
    netname = argv[1]
    specname = argv[2]
    epsilon = float(argv[3])
    with open(netname, 'r') as netfile:
        netstring = netfile.read()
    with open(specname, 'r') as specfile:
        specstring = specfile.read()
    nn = parse_net(netstring)
    x0_low, x0_high = parse_spec(specstring)
    # Classify image using loaded network - Break when image class is not 
    # correctly classified since robustness analysis makes no sense in 
    # this is case (Passing Epsilon = 0 leads the network to classify the img.)
    LB_N0, UB_N0 = get_perturbed_image(x0_low,0)
    label, _ = analyze(nn,LB_N0,UB_N0,0)
    # Start robustness analysis. 
    start = time.time()
    if label == int(x0_low[0]):
        LB_N0, UB_N0 = get_perturbed_image(x0_low,epsilon)
        _, verified_flag = analyze(nn,LB_N0,UB_N0,label)
        if(verified_flag):
            print("verified")
        else:
            print("failed")  
    else:    
        print("image not correctly classified by the network. expected: ",int(x0_low[0]), " classified: ", label)
    end = time.time()
    #print("analysis time: ", (end-start), " seconds")

