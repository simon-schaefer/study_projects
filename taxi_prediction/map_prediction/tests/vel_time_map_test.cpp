#include "CSVReader.h"
#include "StreetMap.h"
#include "Utilities.h"

int main(int argc, char* argv[])
{
    // Check and parse input arguments: train, test, save filename. In case
    // no input arguments are given, take default values.
    std::string TRAIN_FILENAME = "../../data/train_data.csv";
    std::string STREETS_FILE   = "../../imgs/new_streets.ppm";
    std::string VEL_MAP_FILE   = "../../imgs/new_velocity_map.ppm";

    ///////////////////////////////////////////////////////////////////////////
    /// Training data analysis                                              ///
    ///////////////////////////////////////////////////////////////////////////

    // Load data set and get rit of unused data columns.
    CSVReader data(TRAIN_FILENAME);
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
    // Save street map and velocity map visualisation as png file.
    map.plotStreetMap(STREETS_FILE);
    map.plotVelTimeMap(VEL_MAP_FILE, 0);
    map.plotVelTimeMap(VEL_MAP_FILE, 1);
    map.plotVelTimeMap(VEL_MAP_FILE, 9);
    map.plotVelTimeMap(VEL_MAP_FILE, 10);
    map.plotVelTimeMap(VEL_MAP_FILE, 16);
    map.plotVelTimeMap(VEL_MAP_FILE, 18);
    map.plotVelTimeMap(VEL_MAP_FILE, 20);

    return 0;
}