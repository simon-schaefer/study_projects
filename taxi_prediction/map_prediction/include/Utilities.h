#ifndef MAP_PREDICTION_UTILITIES_H
#define MAP_PREDICTION_UTILITIES_H

#include <string>

#include "StreetMap.h"

// Compact storage and access of information that are used for prediction.
// DataSet = Data coordinates are used internally.
// MapSet  = Map coordinates are used internally.
struct DataSet
{
    StreetMap::MapPoint start, end;
    int hour;

    DataSet()
        : start(StreetMap::MapPoint()), end(StreetMap::MapPoint()), hour(-1){}

    DataSet(StreetMap::MapPoint new_start, StreetMap::MapPoint new_end,
            int new_hour) : start(new_start), end(new_end), hour(new_hour){}
};
struct MapSet
{
    StreetMap::MapPoint start, end;
    int hour;

    MapSet()
        : start(StreetMap::MapPoint()), end(StreetMap::MapPoint()), hour(-1){}

    MapSet(StreetMap::MapPoint new_start, StreetMap::MapPoint new_end,
            int new_hour) : start(new_start), end(new_end), hour(new_hour){}
};

// Visualisation of progress using a progress bar and parser arithmetic.
void printProgress
    (double percentage, int width = 60,
     const std::string& pad = "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||");

// Auxiliary functions to avoid initialisation of x and y vectors seperately, as
// there are given in the underlying dataset.
std::vector<StreetMap::MapPoint> mergePoints(
     const std::vector<StreetMap::MapPoint>& starts,
     const std::vector<StreetMap::MapPoint>& ends,
     const std::vector<std::vector<StreetMap::MapPoint> >& paths);

std::vector<StreetMap::MapPoint> mergeCoords(std::vector<int> xs,
                                             std::vector<int> ys);

std::vector< std::vector<StreetMap::MapPoint> > mergePaths(
     const std::vector< std::vector<int> >& x_paths,
     const std::vector< std::vector<int> >& y_paths);

std::vector< DataSet > mergeToDataVector(
    const std::vector<StreetMap::MapPoint>& starts,
    const std::vector<StreetMap::MapPoint>& ends,
    const std::vector<int>& hours);

#endif //MAP_PREDICTION_UTILITIES_H
