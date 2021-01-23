#include "Utilities.h"

#include <cassert>

void printProgress (double percentage, const int width,
                    const std::string& pad)
{
    auto val   = (int)(percentage * 100);
    auto left  = (int)(percentage * width);
    int  right = width - left;
    printf ("\r%3d%% [%.*s%*s]", val, left, pad.c_str(), right, "");
    fflush (stdout);
}

std::vector<StreetMap::MapPoint> mergePoints(const std::vector<StreetMap::MapPoint>& starts,
                                             const std::vector<StreetMap::MapPoint>& ends,
                                             const std::vector<std::vector<StreetMap::MapPoint> >& paths)
{
    std::vector<StreetMap::MapPoint> points;
    // Get resulting size of points for the sake of efficiency.
    size_t resulting_size = starts.size() + ends.size();
    for (const auto& path : paths) resulting_size += path.size();
    // Reallocate points array and fill it.
    points.resize(resulting_size);
    for (const auto& start : starts) points.push_back(start);
    for (const auto& end   : ends)   points.push_back(end);
    for (const auto& path : paths) for (const auto& point : path) points.push_back(point);
    return points;
}

std::vector<StreetMap::MapPoint> mergeCoords(const std::vector<int> xs,
                                             const std::vector<int> ys)
{
    assert(xs.size() == ys.size());
    std::vector<StreetMap::MapPoint> points;
    points.resize(xs.size());
    for(int i = 0; i < points.size(); ++i)
    {
        points[i] = StreetMap::MapPoint(xs[i], ys[i]);
    }
    return points;
}

std::vector< std::vector<StreetMap::MapPoint> > mergePaths(const std::vector< std::vector<int> >& x_paths,
                                                           const std::vector< std::vector<int> >& y_paths)
{
    assert(x_paths.size() == y_paths.size());
    std::vector< std::vector<StreetMap::MapPoint> > paths;
    paths.resize(x_paths.size());
    for(int i = 0; i < paths.size(); ++i)
    {
        assert(x_paths[i].size() == y_paths[i].size());
        paths[i].resize(x_paths[i].size());
        for(unsigned int j = 0; j < paths[i].size(); ++j)
        {
            paths[i][j] = StreetMap::MapPoint(x_paths[i][j], y_paths[i][j]);
        }
    }
    return paths;
}

std::vector< DataSet > mergeToDataVector(const std::vector<StreetMap::MapPoint>& starts,
                                         const std::vector<StreetMap::MapPoint>& ends,
                                         const std::vector<int>& hours)
{
    std::vector< DataSet > data_vector;
    const size_t num_samples = starts.size();
    assert(num_samples == ends.size());
    assert(num_samples == hours.size());
    data_vector.resize(num_samples);
    for(int i = 0; i < num_samples; ++i)
    {
        data_vector[i].start = starts[i];
        data_vector[i].end   = ends[i];
        data_vector[i].hour  = hours[i];
    }
    return data_vector;
}