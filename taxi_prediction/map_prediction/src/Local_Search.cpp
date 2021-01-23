#include "Local_Search.h"

#include <fstream>
#include <random>

LocalSearch::LocalSearch(const StreetMap& map,
                         const double weight_end_distance,
                         const double weight_mo_direction,
                         const double weight_mean_velocity)
    : Predictor(map),
      _weight_end_dis(weight_end_distance),
      _weight_directi(weight_mo_direction),
      _weight_meanvel(weight_mean_velocity){}

void LocalSearch::optimise(const std::vector< DataSet >& sample_vector,
                           const std::vector<double>& true_lengths,
                           const std::string& log_file_name,
                           bool random)
{
    // Get parameter combinations using random sampling.
    int iteration = 0;
    double opt_weights[3] = {0.0, 0.0, 0.0}; double opt_acc = 99.9;
    // Get testing weights - Either Monte Carlo or grid search.
    double weights_end_dis[OPTIM_ITERS];
    double weights_meanvel[OPTIM_ITERS];
    double weights_directi[OPTIM_ITERS];
    if (random)
    {
        std::random_device rd; std::mt19937 gen(rd());
        std::uniform_real_distribution<> dis_end_dis(-10.0, 10.0);
        std::uniform_real_distribution<> dis_meanvel(WEIGHT_MEANVEL/3, WEIGHT_MEANVEL*3);
        std::uniform_real_distribution<> dis_directi(-4.0, 4.0);
        for (int i = 0; i < OPTIM_ITERS; ++i)
        {
            weights_end_dis[i] = dis_end_dis(gen);
            weights_meanvel[i] = dis_meanvel(gen);
            weights_directi[i] = dis_directi(gen);
        }
    }
    else
    {
        const double grid_size = pow(OPTIM_ITERS, 1.0/3.0);
        int i = 0;
        for (int x = 0; x < grid_size; ++x)
            for (int y = 0; y < grid_size; ++y)
                for (int z = 0; z < grid_size; ++z)
                {
                    weights_end_dis[i] = WEIGHT_END_DIS - 1.0 + 2.0*(double)x/OPTIM_ITERS;
                    weights_meanvel[i] = WEIGHT_MEANVEL - 1.0 + 2.0*(double)y/OPTIM_ITERS;
                    weights_directi[i] = WEIGHT_DIRECTI - 0.2 + 0.5*(double)z/OPTIM_ITERS;
                    i++;
                    if (i >= OPTIM_ITERS) break;
                }
    }
    // Open log file and write header.
    const bool do_logging = !log_file_name.empty();
    std::ofstream file;
    if(do_logging)
    {
        file.open(log_file_name, std::ios::trunc);
        file << "end_dis,vel_mean,direction,accuracy" << std::endl;
    }
    // Execute parameter search.
    for (int i = 0; i < OPTIM_ITERS; ++i)
    {
        _weight_end_dis = weights_end_dis[i];
        _weight_meanvel = weights_meanvel[i];
        _weight_directi = weights_directi[i];
        const double acc = predictionAccuracy(sample_vector, true_lengths);
        if (acc < opt_acc)
        {
            opt_weights[0] = _weight_end_dis;
            opt_weights[1] = _weight_meanvel;
            opt_weights[2] = _weight_directi;
            opt_acc = acc;
        }
        iteration++;
        printProgress((double)iteration / OPTIM_ITERS);
        if (iteration % (OPTIM_ITERS/10) == 0)
        {
            printf("\n\nOptimal so far with acc = %f\n", opt_acc);
            printf("Distance to end = %f\n", opt_weights[0]);
            printf("Mean velocity = %f\n", opt_weights[1]);
            printf("Moving direction = %f\n\n", opt_weights[2]);
        }
        if(do_logging)
        {
            std::string row_string;
            row_string += std::to_string(_weight_end_dis) + ", ";
            row_string += std::to_string(_weight_meanvel) + ", ";
            row_string += std::to_string(_weight_directi) + ", ";
            row_string += std::to_string(acc) + ", ";
            file << row_string << std::endl;
        }
    }
    _weight_end_dis = opt_weights[0];
    _weight_meanvel = opt_weights[1];
    _weight_directi = opt_weights[2];
    printf("\nOptimal parameter set after %d iterations\n", OPTIM_ITERS);
    printf("Distance to end = %f\n", _weight_end_dis);
    printf("Mean velocity = %f\n", _weight_meanvel);
    printf("Moving direction = %f\n", _weight_directi);
    file.close();
}

double LocalSearch::predictPath(MapSet& sample, t_point_vector &path)
{
    double traj_length = 0.0;
    // Moving direction (should be preserved in optimisation afterwards).
    double direction[] = {0.0, 0.0};
    // Iteratively path prediction.
    StreetMap::MapPoint current(sample.start);
    t_point_vector neighbours;
    path.reserve(SEARCH_ITERATIONS); path.push_back(current);
    for (unsigned int k = 0; k < SEARCH_ITERATIONS; ++k)
    {
        // Break loop when end point is in range.
        if (_street_map.distance(current, sample.end) < TERMINATION_DIS) break;
        // Find minimal value of optimisation function in neighbour cells (i.e. min
        // distance and max density).
        neighbourPoints(current, neighbours);
        StreetMap::MapPoint best_point(current.x, current.y, 9999);
        for (auto& neigh : neighbours)
        {
            // For every candidate determine optimisation function value.
            const double direc[] = {(neigh.x - current.x)*direction[0],
                                    (neigh.y - current.y)*direction[1]};
            //neigh.cost = + _weight_end_dis*_street_map.distance(neigh, sample.end)
            //             - _weight_directi*(direc[0] + direc[1])
            //             - _weight_meanvel*_street_map.velocity(neigh, sample.hour);
            neigh.cost = _weight_meanvel*_street_map.velocity(neigh, sample.hour);
            // Check if candidate exceeds current best point.
            if (neigh.cost < best_point.cost) best_point = neigh;
        }
        // Set next point to best candidate, iterate costs, append to trajectory
        // points and update direction.
        current = best_point;
        path.push_back(current);
        direction[0] = current.x - path.end()[-2].x;
        direction[1] = current.y - path.end()[-2].y;
        traj_length += _street_map.distance(current, path.end()[-2]);
        // Check for repetition actions in the paths end. If the path is repeated in the
        // last k elements the search breaks and the remaining distance is approximated
        // by euclidean distance.
        if (path.size() < SEARCH_BACK_DISTANCE) continue;
        for (int i = 2; i < SEARCH_BACK_DISTANCE; ++i)
        {
            const StreetMap::MapPoint last_point(*(path.end() - i));
            if (_street_map.distance(current, last_point) < STEP_WIDTH/2)
            {
                traj_length += _street_map.distance(current, sample.end);
                path.push_back(sample.end);
                path.shrink_to_fit();
                return traj_length;
            }
        }
    }
    // Add end point and termination distance to path length and return.
    traj_length += TERMINATION_DIS;
    path.push_back(sample.end);
    path.shrink_to_fit();
    return traj_length;
}