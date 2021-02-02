import sys

# Navigate to folder which contains ELINA
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

libc = CDLL(find_library('c'))
cstdout = c_void_p.in_dll(libc, 'stdout')

class layers:
    def __init__(self):
        self.layertypes = []
        self.weights = []
        self.biases = []
        self.numlayer = 0
        self.ffn_counter = 0

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


def generate_linexpr0(weights, bias, size):
    """Generates a linear constraint with ELINA. Returns elina_linexpr object."""
    linexpr0 = elina_linexpr0_alloc(ElinaLinexprDiscr.ELINA_LINEXPR_DENSE, size)
    cst = pointer(linexpr0.contents.cst)
    elina_scalar_set_double(cst.contents.val.scalar, bias)
    for i in range(size):
        elina_linexpr0_set_coeff_scalar_double(linexpr0,i,weights[i])
    return linexpr0

def analyze(nn, LB_N0, UB_N0, label):
    """Analyzes the robustness of a NN versus L-infty norm perturbations of strength epsilon.
    If epsilon was 0, i.e. LB_N0 == UB_N0 no robustness verification is done and instead the label
    of the given image is computed in a forward pass.

    Parameters:
        nn :    layers object
                Contains the parsed NN with weights, biases, activations and no. of layers
        LB_N0:  1d np.array
                Contains the lower bound pixel values
        UB_N0:  1d np.array
                Contains the upper bound pixel values
        label:  int
                Contains the correct label

    Returrns:
        predicted_label :   int
        verified_flag   :   bool
    """

    num_pixels = len(LB_N0)
    nn.ffn_counter = 0
    numlayer = nn.numlayer

    ## generate elina box
    man = elina_box_manager_alloc()
    itv = elina_interval_array_alloc(num_pixels)
    for i in range(num_pixels):
        elina_interval_set_double(itv[i],LB_N0[i],UB_N0[i])

    ## construct input abstraction
    ## create a hypercube (box) at manager man
    element = elina_abstract0_of_box(man, intdim=0, realdim=num_pixels, tinterval=itv)
    elina_interval_array_free(itv,num_pixels) #deallocate itv

    ## pass through layers of net
    for layerno in range(numlayer):
        if(nn.layertypes[layerno] in ['ReLU', 'Affine']):
           weights = nn.weights[nn.ffn_counter]
           biases = nn.biases[nn.ffn_counter]
           dims = elina_abstract0_dimension(man,element)
           num_in_pixels = dims.intdim + dims.realdim  #for elina box intdim = 0, realdim = num_pixels
           num_out_pixels = len(weights)

            ## add extra dimensions for the output
           dimadd = elina_dimchange_alloc(intdim=0, realdim=num_out_pixels)    #to add the new dimensions
           for i in range(num_out_pixels):
               dimadd.contents.dim[i] = num_in_pixels
           elina_abstract0_add_dimensions(man, destructive=True, a1=element, dimchange=dimadd, project=False)
           elina_dimchange_free(dimadd) #deallocate dimchange object

           ## change memory allocation - now array is contingous in memory (C order)
           np.ascontiguousarray(weights, dtype=np.double)
           np.ascontiguousarray(biases, dtype=np.double)
           var = num_in_pixels

           ## handle affine layer
           for i in range(num_out_pixels):
               tdim= ElinaDim(var)
               linexpr0 = generate_linexpr0(weights[i],biases[i],num_in_pixels)
               element = elina_abstract0_assign_linexpr_array(man, True, element, tdim, linexpr0, 1, None)
               var+=1

            ## remove the input dimensions
           dimrem = elina_dimchange_alloc(0,num_in_pixels) #to remove old dimensions
           for i in range(num_in_pixels):
               dimrem.contents.dim[i] = i
           elina_abstract0_remove_dimensions(man, True, element, dimrem)
           elina_dimchange_free(dimrem) #deallocate dimension changer

           # handle ReLU layer 
           if(nn.layertypes[layerno]=='ReLU'):
              element = relu_box_layerwise(man,True,element,0, num_out_pixels)
           nn.ffn_counter+=1 

        else:
           print(' net type not supported')
   
    dims = elina_abstract0_dimension(man,element)
    output_size = dims.intdim + dims.realdim
    # get bounds for each output neuron
    bounds = elina_abstract0_to_box(man,element)

           
    # if epsilon is zero, try to classify else verify robustness #TODO: Change it so that we don't execute the entire for loop above if we just wish to classify
    
    verified_flag = True
    predicted_label = 0
    if(LB_N0[0]==UB_N0[0]): #if first elt's of LB and UB are equal, epsilon was 0
        for i in range(output_size):
            inf = bounds[i].contents.inf.contents.val.dbl
            flag = True
            # go over all other labels and check if lower activation bound for label i
            # is higher than highest activation bound for all other labels j!=i.
            for j in range(output_size):
                if(j!=i):
                   sup = bounds[j].contents.sup.contents.val.dbl
                   if(inf<=sup):
                      flag = False
                      break
            if(flag):
                predicted_label = i
                break    
    else:
        inf = bounds[label].contents.inf.contents.val.dbl
        for j in range(output_size):
            # go over all other labels and check if lower activation bound for correct label
            # is higher than highest activation bound for all other labels j!=label. If it is, network is robust.
            if(j!=label):
                sup = bounds[j].contents.sup.contents.val.dbl
                if(inf<=sup):
                    predicted_label = label
                    verified_flag = False
                    break

    elina_interval_array_free(bounds,output_size) ##Free elina objects = deallocate
    elina_abstract0_free(man,element)
    elina_manager_free(man)        
    return predicted_label, verified_flag



if __name__ == '__main__':
    from sys import argv
    if len(argv) < 3 or len(argv) > 4:
        print('usage: python3.6 ' + argv[0] + ' net.txt spec.txt [timeout]')
        exit(1)

    netname = argv[1]
    specname = argv[2]
    epsilon = float(argv[3])
    #c_label = int(argv[4])
    with open(netname, 'r') as netfile:
        netstring = netfile.read()
    with open(specname, 'r') as specfile:
        specstring = specfile.read()
    nn = parse_net(netstring)
    x0_low, x0_high = parse_spec(specstring)
    LB_N0, UB_N0 = get_perturbed_image(x0_low,0) #TODO: Is this used to check if network was parsed in correctly?
    
    label, _ = analyze(nn,LB_N0,UB_N0,0) #Simply classifies the image. Passing Epsilon = 0 leads the network to classify the img.
    start = time.time()
    if(label==int(x0_low[0])):
        LB_N0, UB_N0 = get_perturbed_image(x0_low,epsilon)  #now image is really perturbed
        _, verified_flag = analyze(nn,LB_N0,UB_N0,label)
        if(verified_flag):
            print("verified")
        else:
            print("can not be verified")  
    else:
        print("image not correctly classified by the network. expected label ",int(x0_low[0]), " classified label: ", label)
    end = time.time()
    print("analysis time: ", (end-start), " seconds")
    

