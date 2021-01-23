#ifndef MAP_PREDICTION_OPTIMAL_TIME_SEARCH_H
#define MAP_PREDICTION_OPTIMAL_TIME_SEARCH_H

#include <vector>

#include "Predictor.h"

class OptimalTimeSearch : public Predictor
{
    class Node;
    typedef std::vector < std::vector< Node > > t_node_map;

    t_node_map _node_map;

    const static uint8_t STATE_UNKNOWN        = 0;
    const static uint8_t STATE_VISITED        = 1;
    const static uint8_t STATE_FROZEN         = 2;

    const static uint32_t MAX_SEARCH_STEPS    = UINT32_MAX;

    constexpr static double HEURISTIC_MAX_VELOCITY = 60.0;

public:
    explicit OptimalTimeSearch(const StreetMap& map);

protected:
    // Predict the trajectory length from start to end point, given the internal
    // street map of predictable space. In AStarSearch the AStar algorithm is used,
    // assuming the true trajectory is (or is close to) the trajectory with
    // smallest length (Heuristic = euclidean distance). In opposite to AStar_Search
    // the optimal time policy is used, i.e. the trajectory is chosen such that
    // the time (length/velocity) is minimised.
    // Note: In opposite to the "standard" AStar algorithm no queues are used to store
    //       the node's state, instead the status of every node is directly
    //       saved with the node (unknown, visited, frozen).
    double predictPath(MapSet& sample, t_point_vector &path) override;

private:

    // Search closest street point in internal street map (UCS with goal = true node).
    // @param[in]   start_point         starting point, will be changed to closest point!
    // Note: Attention the internal node map is reset during execution.
    double closestStreetPoint(StreetMap::MapPoint& start_point);

    double heuristic(const StreetMap::MapPoint& point,
                     const MapSet& sample) const;

    void resetNodeMap();

    // The Node class extends the MapPoint due to the needs of the AStar
    // algorithm to store the cost w/o heuristic and the state of every
    // node. Sorting by the cost (f) is preserved.
    class Node : public StreetMap::MapPoint
    {
    public:

        double  g;
        uint8_t state;
        StreetMap::MapPoint previous;

    public:
        Node()
            : MapPoint(), g(999.9), state(STATE_UNKNOWN), previous(-1, -1){}

        Node(int x_new, int y_new, double cost_new = 999.9,
             double g_new = 999.9, uint8_t state_new = STATE_UNKNOWN,
             StreetMap::MapPoint previous_new = StreetMap::MapPoint(-1, -1))
            : MapPoint(x_new, y_new, cost_new), g(g_new),
              state(state_new), previous(previous_new){}
    };
};

#endif //MAP_PREDICTION_OPTIMAL_TIME_SEARCH_H
