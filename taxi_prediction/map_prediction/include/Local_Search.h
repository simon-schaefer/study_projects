#ifndef MAP_PREDICTION_LOCAL_SEARCH_H
#define MAP_PREDICTION_LOCAL_SEARCH_H

#include "Predictor.h"

class LocalSearch : public Predictor
{
    double _weight_end_dis;
    double _weight_directi;
    double _weight_meanvel;

    constexpr static double WEIGHT_END_DIS    = 1.0;
    constexpr static double WEIGHT_DIRECTI    = 0.15;
    constexpr static double WEIGHT_MEANVEL    = 1.0;

    const static int OPTIM_ITERS              = 20000;

    const static int SEARCH_BACK_DISTANCE     = 5;
    const static int SEARCH_ITERATIONS        = 200;

public:

    explicit LocalSearch(const StreetMap& map,
                         double weight_end_distance = WEIGHT_END_DIS,
                         double weight_mo_direction = WEIGHT_DIRECTI,
                         double weight_mean_velocity= WEIGHT_MEANVEL);

    // Optimise weights of optimisation cost function, by doing a grid search
    // or Monte Carlo sampling. For every parameter set TESTING_SAMPLES samples
    // are tested and the median of the error is determined.
    void optimise(const std::vector< DataSet >& sample_vector,
                  const std::vector<double>& true_lengths,
                  const std::string& log_file_name,
                  bool random = true);

protected:
    // Predict the trajectory length from start to end point, given the internal
    // street map of predictable space. Thus, we look for the path going
    // to minimizing direction in  every step (Inverse-Hill-Climbing).
    double predictPath(MapSet& sample, t_point_vector &path) override;
};


#endif //MAP_PREDICTION_LOCAL_SEARCH_H
