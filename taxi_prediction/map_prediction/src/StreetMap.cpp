#include "StreetMap.h"

#include <algorithm>
#include <cassert>
#include <fstream>
#include <iostream>
#include <cmath>
#include <queue>

StreetMap::StreetMap()
{
    _raw_street_map = nullptr;
    _x_min = 0; _y_min = 0; _size_x = 0; _size_y = 0;
}

void StreetMap::buildMap(const std::vector<MapPoint>& points)
{
    // Get minimal and maximal element to determine the size of the map.
    _x_min = 9999; _y_min = 9999; int x_max = -9999, y_max = -9999;
    for(const auto& point : points)
    {
        const int x = point.x, y = point.y;
        if(_x_min > x) _x_min = x;
        if(x_max < x)  x_max  = x;
        if(_y_min > y) _y_min = y;
        if(y_max < y)  y_max  = y;
    }
    // Resulting size is distance between max and min point.
    _size_x = x_max - _x_min + 1; _size_y = y_max - _y_min + 1;
    // Build up and fill street map in given size.
    _raw_street_map = new int*[_size_x];
    for (int i = 0; i < _size_x; ++i) _raw_street_map[i] = new int[_size_y];
    for(const auto& point : points)
    {
        MapPoint point_data = pointToMap(point);
        _raw_street_map[point_data.x][point_data.y] += 1;
    }
    // Build boolean map (smaller representation of street map).
    _street_map.resize((size_t)_size_x);
    for (int x = 0; x < _size_x; ++x)
    {
        _street_map[x].resize((size_t)_size_y);
        for (int y = 0; y < _size_y; ++y) _street_map[x][y] = (_raw_street_map[x][y] != 0);
    }
    std::cout << "Build map with size x: " << _size_x << ", y: " << _size_y << std::endl;
}

void StreetMap::buildVelocityTimeMap(const std::vector<std::vector<MapPoint> >& paths,
                                     const std::vector<int>& hours)
{
    assert(_size_x > 0 && _size_y > 0);
    // Check valid inputs (same number of samples).
    const size_t num_samples = paths.size();
    assert(num_samples == hours.size());
    // Create buffer velocity map to average later on.
    std::vector< std::vector<std::vector<double> > > buffer_vel;
    std::vector< std::vector<std::vector<int> > >    buffer_index;
    buffer_vel.resize((size_t)_size_x);
    buffer_index.resize((size_t)_size_x);
    for (int x = 0; x < _size_x; ++x)
    {
        buffer_vel[x].resize((size_t)_size_y);
        buffer_index[x].resize((size_t)_size_y);
        for (int y = 0; y < _size_y; ++y)
        {
            buffer_vel[x][y].resize(24);
            buffer_index[x][y].resize(24);
        }
    }
    for(size_t k = 0; k < num_samples; ++k)
    {
        std::vector<StreetMap::MapPoint> path_map = vecToMap(paths[k]);
        for(size_t i = 1; i < paths[k].size() - 1; ++i)
        {
            const double point_vel = distance(path_map[i - 1], path_map[i]);
            buffer_vel[path_map[i].x][path_map[i].y][hours[k]] += point_vel;
            buffer_index[path_map[i].x][path_map[i].y][hours[k]]++;
        }
    }
    // Create (i.e. resize) velocity time maps on the basis of 24 hours.
    // and average buffer arrays to create velocity-time-map.
    _velocity_time_map.resize(24);
    for(int h = 0; h < 24; ++h)
    {
        _velocity_time_map[h].resize((size_t)_size_x);
        for (int x = 0; x < _size_x; ++x)
        {
            _velocity_time_map[h][x].resize((size_t)_size_y);
            for (int y = 0; y < _size_y; ++y)
            {
                const int n = buffer_index[x][y][h];
                if(n == 0) _velocity_time_map[h][x][y] = 0.001;
                else _velocity_time_map[h][x][y] = buffer_vel[x][y][h]/n;
            }
        }
    }
}

void StreetMap::applyMultipleHitFilter(const int threshold)
{
    assert(_size_x > 0 && _size_y > 0);
    for (int x = 0; x < _size_x - 1; ++x)
        for (int y = 0; y < _size_y - 1; ++y)
        {
            _street_map[x][y] = _raw_street_map[x][y] >= threshold;
        }
    printf("Applied multiple hit filter with %d hits\n", threshold);
}

void StreetMap::applyPoolingFilter(const int threshold)
{
    //assert(_size_x == 0 || _size_y == 0);
    t_street_map buffer_map(_street_map);
    for (int x = 0; x < _size_x - 1; ++x)
        for (int y = 0; y < _size_y - 1; ++y)
        {
            const MapPoint point(x, y);
            buffer_map[x][y] = density(point) >= threshold && boolean(point);
        }
    std::move(buffer_map.begin(), buffer_map.end(), _street_map.begin());
    printf("Applied pooling filter with %d neighs\n", threshold);
}

const bool StreetMap::valid(const MapPoint& point) const
{
    return 0 <= point.x && point.x < _size_x && 0 <= point.y && point.y < _size_y;
}

const bool StreetMap::boolean(const MapPoint& point) const
{
    return _street_map[point.x][point.y];
}

const int StreetMap::density(const MapPoint& point, const int delta) const
{
    int street_points = 0;
    for (const auto& neigh : neighbours(point, delta))
    {
        if (boolean(neigh)) street_points++;
    }
    return street_points;
}

const int StreetMap::traffic(const MapPoint& point) const
{
    return _raw_street_map[point.x][point.y];
}

const double StreetMap::velocity(const MapPoint& point, const int hour) const
{
    return _velocity_time_map[hour][point.x][point.y];
}

std::vector<StreetMap::MapPoint> StreetMap::neighbours(const MapPoint& point,
                                                       const int delta) const
{
    std::vector<MapPoint> neighbours;
    for (int dx = -delta; dx <= +delta; ++dx)
        for (int dy = -delta; dy <= +delta; ++dy)
    {
        if (dx == 0 && dy == 0) continue;
        MapPoint neigh = MapPoint(point.x + dx, point.y + dy);
        if (valid(neigh)) neighbours.push_back(neigh);
    }
    return neighbours;
}

double StreetMap::distance(const MapPoint& start, const MapPoint& end)
{
    return sqrt((start.x - end.x)*(start.x - end.x) + (start.y - end.y)*(start.y - end.y));
}

StreetMap::MapPoint StreetMap::pointToMap(const MapPoint& point_data) const
{
    return {point_data.x - _x_min, point_data.y - _y_min};
}

StreetMap::MapPoint StreetMap::pointToData(const MapPoint& point_map) const
{
    return {point_map.x + _x_min, point_map.y + _y_min};
}

std::vector<StreetMap::MapPoint> StreetMap::vecToMap(const std::vector<MapPoint>& vec_data) const
{
    std::vector<MapPoint> vec_map;
    vec_map.resize(vec_data.size());
    for (unsigned int k = 0; k < vec_data.size(); ++k)
    {
        vec_map[k] = pointToMap(vec_data[k]);
    }
    return vec_map;
}

std::vector<StreetMap::MapPoint> StreetMap::vecToData(const std::vector<MapPoint>& vec_map) const
{
    std::vector<MapPoint> vec_data;
    vec_data.resize(vec_map.size());
    for (unsigned int k = 0; k < vec_data.size(); ++k)
    {
        vec_data[k] = pointToData(vec_map[k]);
    }
    return vec_data;
}

struct Color
{
    char r,g,b;
    Color(const char red, const char green, const char blue)
        : r(red), g(green), b(blue){}
};


void StreetMap::plotStreetMap(const std::string &save_file,
                              const std::vector<MapPoint> &path,
                              bool data_coordinates) const
{
    assert(_size_x > 0 && _size_y > 0);
    // Copy path and convert to data coordinates if necessary.
    std::vector<MapPoint> new_path = !data_coordinates ? path:vecToMap(path);
    // Write image pixel per pixel.
    std::ofstream img(save_file, std::ios::binary);
    img.write("P6 ", 3); img.write("1204 ", 5);
    img.write("900 ", 4); img.write("255 ", 4);
    for (int y = 0; y < _size_y; ++y)
        for (int x = 0; x < _size_x; ++x)
    {
        const MapPoint point(x, y);
        const auto it = std::find(new_path.begin(), new_path.end(), point);
        if(it != new_path.end())
        {
            Color pixel((char)255, (char)0, (char)0);
            img.write(reinterpret_cast<char*>(&pixel), sizeof(pixel));
        }
        else if(_street_map[x][y])
        {
            Color pixel((char)100, (char)100, (char)100);
            img.write(reinterpret_cast<char*>(&pixel), sizeof(pixel));
        }
        else
        {
            Color pixel((char)255, (char)255, (char)255);
            img.write(reinterpret_cast<char*>(&pixel), sizeof(pixel));
        }
    }
    img.close();
    printf("Saved street map to file %s\n", save_file.c_str());
}

void StreetMap::plotVelTimeMap(const std::string& save_file, int hour) const
{
    assert(_size_x > 0 && _size_y > 0);
    // Get maximum velocity.
    double maximum_vel = 0.0, mean = 0.0;
    for(int y = 0; y < _size_y; ++y)
        for(int x = 0; x < _size_x; ++x)
    {
        if(_velocity_time_map[hour][x][y] > maximum_vel)
        {
            maximum_vel = _velocity_time_map[hour][x][y];
        }
        mean += _velocity_time_map[hour][x][y];
    }
    mean /= _size_x*_size_y;
    double variance = 0.0;
    for(int y = 0; y < _size_y; ++y)
        for(int x = 0; x < _size_x; ++x)
            variance += std::pow(_velocity_time_map[hour][x][y] - mean, 2);
    variance = std::sqrt(variance / (_size_x*_size_y - 1));
    printf("\n\nHour %d: Mean-Velocity map characteristics\n", hour);
    printf("Maximum = %f\n", maximum_vel);
    printf("Mean = %f\n", mean); printf("Variance = %f\n", variance);
    // Write image pixel per pixel.
    std::string filename = save_file;
    filename.insert(filename.length()-4, std::to_string(hour));
    std::ofstream img(filename, std::ios::binary);
    img.write("P6 ", 3); img.write("1204 ", 5);
    img.write("900 ", 4); img.write("255 ", 4);
    for (int y = 0; y < _size_y; ++y)
        for (int x = 0; x < _size_x; ++x)
    {
        const double velocity = _velocity_time_map[hour][x][y];
        auto blue  = static_cast<int>(255*(std::exp(-velocity/30)));
        auto green = static_cast<int>(255*(std::exp(-velocity/30)));
        Color pixel((char)255, (char)green, (char)blue);
        img.write(reinterpret_cast<char*>(&pixel), sizeof(pixel));
    }
    img.close();
    printf("Saved velocity map to file %s\n", filename.c_str());
}

void StreetMap::fillMap(const bool fill_value, const int x_size, const int y_size)
{
    _size_x = x_size; _size_y = y_size;
    _street_map.resize((size_t)_size_x);
    for (int x = 0; x < _size_x; ++x)
    {
        _street_map[x].resize((size_t)_size_y);
        for (int y = 0; y < _size_y; ++y) _street_map[x][y] = fill_value;
    }
    std::cout << "Build map with size x: " << _size_x << ", y: " << _size_y << std::endl;
}