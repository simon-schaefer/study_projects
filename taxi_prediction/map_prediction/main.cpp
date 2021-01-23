#include <cassert>
#include <cmath>
#include <chrono>
#include <iostream>
#include <mutex>
#include <thread>
#include <vector>

#include "CSVReader.h"
#include "StreetMap.h"
#include "AStar_Search.h"

std::mutex thread_mutex;

void openThread(const int index, const int start_index, const int end_index,
                const std::vector<StreetMap::MapPoint>& start_points,
                const std::vector<StreetMap::MapPoint>& end_points,
                const std::vector<int>& hours,
                const StreetMap& map,
                std::vector<double>& predictions)
{
    AStarSearch predictor(map);
    for(int k = start_index; k < end_index; ++k)
    {
        std::vector<StreetMap::MapPoint> path;
        const DataSet sample(start_points[k], end_points[k], hours[k]);
        predictions[k] = predictor.predict(sample, path);
        if((k - start_index) % 1000 == 0)
        {
            thread_mutex.lock();
            printf("Thread %d reached %d out of %d predictions\n",
                   index, k - start_index, end_index - start_index);
            thread_mutex.unlock();
        }
    }
}

int main(int argc, char* argv[])
{
    // Check and parse input arguments: train, test, save filename. In case
    // no input arguments are given, take default values.
    const std::string TRAIN_FILENAME = "../../data/train_data.csv";
    const std::string TEST_FILENAME  = "../../data/test.csv";
    const std::string SAVE_FILENAME  = "../../predictions/test_astar.csv";
    // Number of threads the prediction should run in.
    const int NUM_THREADS = 6;

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
    /// Test data prediction                                                ///
    ///////////////////////////////////////////////////////////////////////////

    // Load and predict test data set.
    CSVReader test(TEST_FILENAME);
    const auto start_test_points = mergeCoords(test.getTypeVector<int>("X_START"),
                                               test.getTypeVector<int>("Y_START"));
    const auto end_test_points   = mergeCoords(test.getTypeVector<int>("X_END"),
                                               test.getTypeVector<int>("Y_END"));
    const auto hours_test        = test.getHours("TIMESTAMP");
    assert(start_test_points.size() == end_test_points.size());
    const size_t num_test = start_points.size();
    std::cout << "Samples to predict = " << num_test << std::endl;
    // Predict test samples and write results into file.
    std::vector<double> test_traj_length; test_traj_length.resize(num_test);
    // Start threads to run and catch (join) them later on.
    std::thread threads[NUM_THREADS];
    for(int i = 0; i < NUM_THREADS; ++i)
    {
        const int start_index = i* static_cast<int>(std::ceil(num_test/NUM_THREADS));
        int end_index   = (i+1)* static_cast<int>(std::ceil(num_test/NUM_THREADS));
        end_index       = std::min(end_index, (int)num_test);
        threads[i]      = std::thread(openThread, i, start_index, end_index,
                                      std::ref(start_test_points),
                                      std::ref(end_test_points),
                                      std::ref(hours_test),
                                      std::ref(map),
                                      std::ref(test_traj_length));
    }
    for(auto& thread : threads) thread.join();
    // Write results into csv file and save file.
    test.addTypeVector<double>("TRAJ_OPTIMAL", test_traj_length);
    test.save(SAVE_FILENAME);

    return 0;
}