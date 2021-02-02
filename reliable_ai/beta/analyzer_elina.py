def analyze_box_elina(nn, LB_N0, UB_N0, label): 
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

    def generate_linexpr0(weights, bias, size):
        """Generates a linear constraint with ELINA. 
        Returns elina_linexpr object."""
        linexpr0 = elina_linexpr0_alloc(ElinaLinexprDiscr.ELINA_LINEXPR_DENSE, size)
        cst = pointer(linexpr0.contents.cst)
        elina_scalar_set_double(cst.contents.val.scalar, bias)
        for i in range(size):
            elina_linexpr0_set_coeff_scalar_double(linexpr0,i,weights[i])
        return linexpr0
        
    num_pixels = len(LB_N0)
    nn.ffn_counter = 0
    numlayer = nn.numlayer 
    # Generate elina box.
    man = elina_box_manager_alloc()
    itv = elina_interval_array_alloc(num_pixels)
    for i in range(num_pixels):
        elina_interval_set_double(itv[i],LB_N0[i],UB_N0[i])
    # Construct input abstraction, i.e. create a hypercube (box) at manager man.
    element = elina_abstract0_of_box(man, 0, num_pixels, itv)
    elina_interval_array_free(itv,num_pixels)
    # Pass through layers of net.
    for layerno in range(numlayer):
        if(nn.layertypes[layerno] in ['ReLU', 'Affine']):
           weights = nn.weights[nn.ffn_counter]
           biases = nn.biases[nn.ffn_counter]
           dims = elina_abstract0_dimension(man,element)
           # For elina box intdim = 0, realdim = num_pixels.
           num_in_pixels = dims.intdim + dims.realdim 
           num_out_pixels = len(weights)
           # Add extra dimensions for the output. 
           dimadd = elina_dimchange_alloc(0,num_out_pixels)    
           for i in range(num_out_pixels):
               dimadd.contents.dim[i] = num_in_pixels
           elina_abstract0_add_dimensions(man, True, element, dimadd, False)
           elina_dimchange_free(dimadd)
           # Change memory allocation to contingous in memory (C order).
           np.ascontiguousarray(weights, dtype=np.double)
           np.ascontiguousarray(biases, dtype=np.double)
           var = num_in_pixels
           # Handle affine layer.
           for i in range(num_out_pixels):
               tdim= ElinaDim(var)
               linexpr0 = generate_linexpr0(weights[i],biases[i],num_in_pixels)
               element = elina_abstract0_assign_linexpr_array(man, True, element, tdim, linexpr0, 1, None)
               var+=1
           # Remove the input dimensions (remove old dimensions for next loop). 
           dimrem = elina_dimchange_alloc(0,num_in_pixels) 
           for i in range(num_in_pixels):
               dimrem.contents.dim[i] = i
           elina_abstract0_remove_dimensions(man, True, element, dimrem)
           # Deallocate dimension changer.
           elina_dimchange_free(dimrem)
           # Handle ReLU layer.
           if(nn.layertypes[layerno]=='ReLU'):
              element = relu_box_layerwise(man,True,element,0, num_out_pixels)
           nn.ffn_counter+=1 
        else:
           print(' net type not supported')
   
    dims = elina_abstract0_dimension(man,element)
    output_size = dims.intdim + dims.realdim
    # Get bounds for each output neuron.
    bounds = elina_abstract0_to_box(man,element)
    # If epsilon is zero, try to classify else verify robustness.
    # To classify the network's output we search for the class i which's 
    # activation is greater than the activations of any other class j.
    # TODO: Change it so that we don't execute the entire for loop above 
    # if we just wish to classify
    verified_flag = True
    predicted_label = 0
    if(LB_N0[0]==UB_N0[0]):
        for i in range(output_size):
            inf = bounds[i].contents.inf.contents.val.dbl
            flag = True
            for j in range(output_size):
                if(j!=i):
                   sup = bounds[j].contents.sup.contents.val.dbl
                   if(inf<=sup):
                      flag = False
                      break
            if(flag):
                predicted_label = i
                break
    # After applying throughpassing the interval constraint of every pixel 
    # through the network, every output class has a range of activations. 
    # Robustness can be verified iff the lower bound of the "correct"'s class
    # activation is larger than the upper bounds of every other classes 
    # activation. 
    else:
        inf = bounds[label].contents.inf.contents.val.dbl
        for j in range(output_size):
            if(j!=label):
                sup = bounds[j].contents.sup.contents.val.dbl
                if(inf<=sup):
                    predicted_label = label
                    verified_flag = False
                    break
    # Deallocate storage and return prediction/robustness verification flag. 
    elina_interval_array_free(bounds,output_size)
    elina_abstract0_free(man,element)
    elina_manager_free(man)        
    return predicted_label, verified_flag
