#ifndef MAP_PREDICTION_STREET_MAP_H
#define MAP_PREDICTION_STREET_MAP_H

#include <string>
#include <vector>

class StreetMap
{
    typedef std::vector<std::vector<bool> >   t_street_map;
    typedef std::vector<std::vector<double> > t_velocity_map;

    int**               _raw_street_map;
    int                 _x_min, _y_min;
    int                 _size_x, _size_y;

    t_street_map                 _street_map;
    std::vector<t_velocity_map>  _velocity_time_map;

    const static int POOLING_THRESHOLD      = 3;
    const static int MULTIPLE_HIT_THRESHOLD = 20;

public:

    // The MapPoint class is an compact representation of a node in the
    // map. Next to position (x,y) cost give the opportunity to the
    // predictor (path finder, ...) to store node parameters such that
    // not several maps have to be worked with (e.g. sorting).
    class MapPoint
    {
    public:

        int      x, y;
        double   cost;

    public:
        MapPoint()
            : x(0), y(0), cost(999.9){}

        MapPoint(int x_new, int y_new, double cost_new = 999.9)
            : x(x_new), y(y_new), cost(cost_new){}

        inline bool operator>(const MapPoint& other) const { return cost > other.cost; }
        inline bool operator<(const MapPoint& other) const { return cost < other.cost; }
        inline bool operator==(const MapPoint& other) const{ return other.x==x && other.y==y; }
        inline bool operator!=(const MapPoint& other) const{ return other.x!=x && other.y!=y; }
    };

public:

    StreetMap();

    // Build street map by checking occupancy of each pixel in given points.
    void buildMap(const std::vector<MapPoint>& points);

    // Build velocity maps for every hour of the day (0 - 23), by determining the
    // mean velocity of each trajectory point [distance(k, k+1)/40s] and assigning this
    // velocity to each element of the trajectory. After doing so for every "pixel"
    // the mean velocity determines the velocity of the regarded "pixel".
    void buildVelocityTimeMap(const std::vector<std::vector<MapPoint> >& paths,
                              const std::vector<int>& hours);

    void applyMultipleHitFilter(int threshold=MULTIPLE_HIT_THRESHOLD);
    void applyPoolingFilter(int threshold=POOLING_THRESHOLD);

    const bool valid(const MapPoint& point) const;
    const bool boolean(const MapPoint& point) const;
    const int density(const MapPoint& point, int delta = 1) const;
    const int traffic(const MapPoint& point) const;
    const double velocity(const MapPoint& point, int hour) const;

    std::vector<MapPoint> neighbours(const MapPoint& point, int delta = 1) const;
    inline int sizeX() const { return _size_x; }
    inline int sizeY() const { return _size_y; }

    static double distance(const MapPoint& start, const MapPoint& end);

    MapPoint pointToMap(const MapPoint& point_data) const;
    MapPoint pointToData(const MapPoint& point_map) const;
    std::vector<MapPoint> vecToMap(const std::vector<MapPoint>& vec_data) const;
    std::vector<MapPoint> vecToData(const std::vector<MapPoint>& vec_map) const;

    void plotStreetMap(const std::string &save_file,
                       const std::vector<MapPoint> &path = std::vector<MapPoint>(),
                       bool data_coordinates = true) const;
    void plotVelTimeMap(const std::string& save_file, int hour) const;

public:

    // For matters of testing the map can be filled with a default value and
    // resized to a given size, instead of being built up by data points.
    void fillMap(bool fill_value, int x_size, int y_size);

};

#endif //MAP_PREDICTION_STREET_MAP_H
