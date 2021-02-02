################################################################################
## Function to evaluate runtime 
################################################################################
def evaluate(nn, x_low, netname, label, num_samples_eps=10):
    ''' Evaluate time performance for different variations of the input 
    network in robustness prooving (i.e. several length of network). '''
    # Check network validity. 
    LB_N0, UB_N0 = get_perturbed_image(x0_low,0)
    label, _ = analyze(nn,LB_N0,UB_N0,0)
    assert label == int(x0_low[0])
    num_pixels = len(LB_N0)
    assert (num_pixels == len(UB_N0))
    num_layer = nn.numlayer
    # Create different variations of inputs. 
    variations = []
    for nl in range(num_layer):
        nl = nl + 1 
        nn_new = layers()
        nn_new.layertypes = nn.layertypes[:nl]
        nn_new.weights = nn.weights[:nl]
        nn_new.biases = nn.biases[:nl]
        nn_new.numlayer = nl
        for s in range(num_samples_eps):
            eps = np.random.uniform(0.005, 0.01)  
            LB_N0, UB_N0 = get_perturbed_image(x0_low,eps)
            xl = np.array(LB_N0)
            xu = np.array(UB_N0)  
            variations.append((nn_new, xl, xu, eps))
    # Evaluate different networks and measure runtime. 
    out_file = open("data/new.txt", "a+")
    for net, xl, xu, eps in variations: 
        start_time = time.time()
        iobj = interval_object(xl, xu)
        _, _ = iobj.fit(net)
        xl_out, xu_out = analyze_full_zonotope(net, iobj)
        end_time = time.time()
        # Extract performance parameters and write to output file.
        # Number and type of layers in network.
        num_relu = sum(x == 'ReLU' for x in net.layertypes)
        num_affine = net.numlayer - num_relu
        num_weights = sum(np.array(net.weights[k]).size for k in range(net.numlayer))
        # Weights distribution in last (one) and second last (two) layer. 
        mean_weights_one = net.weights[-1].mean()
        max_weights_one = net.weights[-1].max()
        min_weights_one = net.weights[-1].min()
        # Activation (input image). 
        activ_mean = ((xu + xl)/2).mean()
        activ_median = np.median((xu + xl)/2)
        activ_max = ((xu + xl)/2).max()
        # Deviation between zonotopic and box constraints. 
        dev_box_all = {'mean': None,'max': None,'min': None,'median': None,'norm': None}
        dev_box_one = {'mean': None,'max': None,'min': None,'median': None,'norm': None}
        ## Over the full network (full zonotope vs full box). 
        xl_box, xu_box = xl, xu
        for k in range(net.numlayer):
            xl_box, xu_box = analyze_layer_box(net.weights[k], net.biases[k], 
                                               net.layertypes[k], xl_box, xu_box)
        dev_box_all_distribution = (xl_box+xu_box)/2 - (xl_out+xu_out)/2
        dev_box_all['mean'] = dev_box_all_distribution.mean()
        dev_box_all['max'] = dev_box_all_distribution.max()
        dev_box_all['min'] = dev_box_all_distribution.min()
        dev_box_all['median'] = np.median(dev_box_all_distribution)
        dev_box_all['norm'] = np.linalg.norm(dev_box_all_distribution)
        ## Over the last layer (zonotope until last layer then box). 
        nl = net.numlayer
        if nl > 1: 
            net_prev = layers()
            net_prev.layertypes = net.layertypes[:nl-1]
            net_prev.weights = net.weights[:nl-1]
            net_prev.biases = net.biases[:nl-1]
            net_prev.numlayer = nl - 1
            xl_out_prev, xu_out_prev = analyze_full_zonotope(net_prev, iobj)
            xl_box, xu_box = analyze_layer_box(net.weights[nl-1], net.biases[nl-1], 
                                               net.layertypes[nl-1], 
                                               xl_out_prev, xu_out_prev)
            dev_box_one_distribution = (xl_box+xu_box)/2 - (xl_out+xu_out)/2
            dev_box_one['mean'] = dev_box_one_distribution.mean()
            dev_box_one['max'] = dev_box_one_distribution.max()
            dev_box_one['min'] = dev_box_one_distribution.min()
            dev_box_one['median'] = np.median(dev_box_one_distribution)
            dev_box_one['norm'] = np.linalg.norm(dev_box_one_distribution)                              
        ## Propagate until end using box analysis and check verification. 
        xl_box, xu_box = xl_out, xu_out
        for k in range(net.numlayer, nn.numlayer):
            xl_box, xu_box = analyze_layer_box(nn.weights[k], nn.biases[k], 
                                               nn.layertypes[k], xl_box, xu_box)
        _, verified_flag = prove(xl_box, xu_box, label)
        ## Write sample to output file. 
        out_file.write(
            str(net.numlayer)+" "+str(num_relu)+" "+str(num_affine)+" " \
            + str(num_weights)+" " \
            + str(mean_weights_one)+" "+ str(max_weights_one)+" " \
            + str(min_weights_one)+" "\
            + str(activ_mean)+" "+ str(activ_median)+" "+str(activ_max)+" " \
            + "".join(str(x) + " " for x in dev_box_all.values()) \
            + "".join(str(x) + " " for x in dev_box_one.values()) \
            + str(eps)+" "+str(netname)+" "+str(nn.numlayer) + " "  
            + str(verified_flag) + " " \
            + str(end_time-start_time)+"\n")  
        msg = "Finished after %f s --> #layer=%d, eps=%f, #weights=%d, verified=%d"
        print(msg
            % (end_time - start_time, net.numlayer, eps, num_weights, verified_flag))
    out_file.close()
