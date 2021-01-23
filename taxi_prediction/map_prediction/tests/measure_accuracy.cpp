#include <iostream>
#include <random>

#include "CSVReader.h"
#include "StreetMap.h"
#include "AStar_Search.h"
#include "OptimalTime_Search.h"

int main(int argc, char* argv[])
{
    // Check and parse input arguments: train, test, save filename. In case
    // no input arguments are given, take default values.
    std::string TRAIN_FILENAME = "../../data/train_data.csv";
    std::string MAP_FILE       = "../../imgs/new_map.ppm";
    std::string PATH_PRED_FILE = "../../imgs/bad/pred.ppm";
    std::string PATH_TRUE_FILE = "../../imgs/bad/true.ppm";

    ///////////////////////////////////////////////////////////////////////////
    /// Training data analysis                                              ///
    ///////////////////////////////////////////////////////////////////////////

    // Load data set and get rit of unused data columns.
    CSVReader data(TRAIN_FILENAME);
    const auto traj_lengths = data.getTypeVector<double>("TRAJ_LENGTH");
    const auto start_points = mergeCoords(data.getTypeVector<int>("X_START"),
                                          data.getTypeVector<int>("Y_START"));
    const auto end_points   = mergeCoords(data.getTypeVector<int>("X_END"),
                                          data.getTypeVector<int>("Y_END"));
    const auto paths_true   = mergePaths(data.getArrayVector<int>("X_TRAJECTORY"),
                                         data.getArrayVector<int>("Y_TRAJECTORY"));
    const auto hours        = data.getHours("TIMESTAMP");

    ///////////////////////////////////////////////////////////////////////////
    /// Build and optimise street map                                       ///
    ///////////////////////////////////////////////////////////////////////////

    // Build street map from given start, end points and trajectories.
    StreetMap map;
    map.buildMap(mergePoints(start_points, end_points, paths_true));
    map.buildVelocityTimeMap(paths_true, hours);
    // Apply hit and pooling filter to decrease noise effects in the map.
    map.applyMultipleHitFilter(200);
    // Save map visualisation as png file.
    map.plotStreetMap(MAP_FILE);

    ///////////////////////////////////////////////////////////////////////////
    /// Build prediction (+ performance analysis and optimising)            ///
    ///////////////////////////////////////////////////////////////////////////

    // Measure prediction accuracy.
    OptimalTimeSearch predictor(map);
    // Predict random values and visualise bad estimations.
    std::random_device rd; std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, (int)start_points.size());
    for(int i = 0; i < 20; ++i)
    {
        std::vector<StreetMap::MapPoint> path;
        const int rand_index = dis(gen);
        const DataSet sample(start_points[rand_index],
                             end_points[rand_index], hours[rand_index]);
        const double ex_pred = predictor.predict(sample, path);
        const double ex_true = traj_lengths[rand_index];
        const double error   = abs(ex_true - ex_pred)/ex_true;
        // Print predictions and path length.
        printf("\nPrediction = %f, truth %f and size %li\n", ex_pred, ex_true, path.size());
        printf("Start: %d %d vs. first path point: %d %d\n",
               start_points[rand_index].x, start_points[rand_index].y,
               paths_true[rand_index].begin()->x, paths_true[rand_index].begin()->y);
        printf("End: %d %d vs. last path point: %d %d\n",
               end_points[rand_index].x, end_points[rand_index].y,
               paths_true[rand_index].end()->x, paths_true[rand_index].end()->y);
        // Store misleading examples.
        if(error > 0.2)
        {
            // Predicted path.
            std::string pred_file_name = PATH_PRED_FILE;
            pred_file_name.insert(pred_file_name.length()-4, std::to_string(i));
            map.plotStreetMap(pred_file_name, path);
            // True path.
            std::string true_file_name = PATH_TRUE_FILE;
            true_file_name.insert(true_file_name.length()-4, std::to_string(i));
            map.plotStreetMap(true_file_name, paths_true[rand_index]);
        }
    }
    // Determine median error over a larger amount of samples.
    predictor.accuracy(mergeToDataVector(start_points, end_points, hours),
                       traj_lengths, 1000);
    return 0;
}