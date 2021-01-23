#include <iostream>
#include <random>

#include "CSVReader.h"
#include "StreetMap.h"
#include "AStar_Search.h"
#include "Local_Search.h"

int main(int argc, char* argv[])
{
    // Check and parse input arguments: train, test, save filename. In case
    // no input arguments are given, take default values.
    std::string TRAIN_FILENAME = "../../data/train_data.csv";
    std::string LOG_FILE       = "../../predictions/opt_local.csv";

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
    map.applyMultipleHitFilter();

    ///////////////////////////////////////////////////////////////////////////
    /// Build prediction (+ performance analysis and optimising)            ///
    ///////////////////////////////////////////////////////////////////////////

    // Measure prediction accuracy.
    LocalSearch predictor(map);
    // Predict random values and optimise.
    predictor.optimise(mergeToDataVector(start_points, end_points, hours),
                       traj_lengths, LOG_FILE);
    // Determine median error over a larger amount of samples.
    predictor.accuracy(mergeToDataVector(start_points, end_points, hours),
                       traj_lengths, 10000);
    return 0;
}