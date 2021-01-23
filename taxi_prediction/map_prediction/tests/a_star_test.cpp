#include <string>

#include "StreetMap.h"
#include "AStar_Search.h"

int main(int argc, char* argv[])
{

    std::string TEST_MAP_FILE   = "../../imgs/test_map.ppm";
    std::string PATH_TEST_FILE  = "../../imgs/test_path.ppm";

    // Build map manually (i.e. not from CSV).
    StreetMap map; map.fillMap(true, 1204, 900);
    map.plotStreetMap(TEST_MAP_FILE);

    // Test start and end point.
    const StreetMap::MapPoint start(600, 300);
    const StreetMap::MapPoint end(400, 100);
    const int hour = 12;

    // Visualise path of one result.
    AStarSearch predictor(map);
    std::vector< StreetMap::MapPoint > path;
    predictor.predict(DataSet(start, end, hour), path);
    map.plotStreetMap(PATH_TEST_FILE, path, false);

    return 0;
}