def analyze_layer_zonotope(weights, biases, layer_type, xl, xu):
    ''' Propagate interval constraint through one layer of neural network
    and output lower and upper bound after layer's activation function using 
    zonotope abstract layer. Therefore transform layer inputs into abstract
    domain, so that a zonotope (linear expression) arises for each of the N
    inputs. Propagate these linear expression through layer and find maximal 
    represented interval at the end of layer, using linear solver gurobi.
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
    # Transform layer's input to linear expressions y = a + b*eps with 
    # varying parameter eps = [0,1], such that a = lower- and a+b = upper-bound.
    # In GUROBI each variable is associated to a specific model, therefore we 
    # create linear expressions (to combine them later while propagating) that 
    # are based on a variables initialized in the "layer-model" that is 
    # maximized and minimized later on in order to find the upper and lower 
    # bound of activation. 
    N = xl.size
    zonotopes = []
    model = Model("layer")
    model.setParam('OutputFlag', False)
    for n in range(N): #defined like this our input-zonotope will always be a box
        eps = model.addVar(vtype=GRB.CONTINUOUS, name="eps_"+str(n))
        model.addRange(eps, 0.0, 1.0, "reps_"+str(n))
        expr = LinExpr(xl[n] + (xu[n]-xl[n])*eps)
        zonotopes.append(expr)						
    # Use linear expressions as input for layer, propagate them by combining 
    # them based on layer weights and biases. Find new interval domain by 
    # solving minimization and maximization problem for resulting linear 
    # expression at the end of layer (i.e. after applying activation function).
    M = weights.shape[0]
    xl_next = np.zeros((M,), dtype=np.float64)
    xu_next = np.zeros((M,), dtype=np.float64)
    for m in range(M):  #this transforms our box and then maximizes the upper bound & minimizes the lower bound. In this implementation this gives us exactly a box.
        ws = weights[m,:]
        b = biases[m]
        combined = LinExpr()
        for n in range(N):
            combined.add(ws[n]*zonotopes[n])
        combined.addConstant(b)
        ## TODO: Add activation function handling in zonotopic way.
        ##if layer_type == 'ReLU':
        #   for m in range(M):
        #       h_relu = 'h_'+str(layer)+'_'+str(m)
        #       model.addVariable(vtype=GRB.CONTINOUS, name=h_relu)
        #       slope =  xu[m] / (xu[m] - xl[m])
        #       intercept = xu[m]*xl[m] / (xu[m] - xl[m])
        #       #Add constraints:
        #       model.addConstr(h_relu >= 0)
        #       model.addConstr(h_relu >= h)
        #       model.addConstr(h_relu <= slope * h + intercept)
        model.setObjective(combined, GRB.MAXIMIZE)
        model.optimize()
        xu_next[m] = model.objVal
        model.setObjective(combined, GRB.MINIMIZE)
        model.optimize()
        xl_next[m] = model.objVal
    if layer_type == 'ReLU':
        xl_next[xl_next<0] = 0
        xu_next[xu_next<0] = 0
    return xl_next, xu_next 
