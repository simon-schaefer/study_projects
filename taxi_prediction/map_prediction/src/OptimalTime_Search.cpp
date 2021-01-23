#include <algorithm>
#include <cassert>
#include <fstream>
#include <iostream>
#include <queue>
#include <random>

#include "OptimalTime_Search.h"

OptimalTimeSearch::OptimalTimeSearch(const StreetMap& map)
    : Predictor(map)
{
    // Build and reset node map.
    _node_map.resize((size_t)map.sizeX());
    for (int x = 0; x < map.sizeX(); ++x)
    {
        _node_map[x].resize((size_t) map.sizeY());
    }
    resetNodeMap();
}

double OptimalTimeSearch::predictPath(MapSet& sample, t_point_vector &path)
{
    double traj_length = 0.0;
    // Prepare path and neighbours vector, i.e. allocate storage.
    path.clear(); t_point_vector neighbours;
    // Get closest street point for start and end of path.
    traj_length += closestStreetPoint(sample.start);
    traj_length += closestStreetPoint(sample.end);
    // Reset g, f(cost) and state of nodes in map.
    resetNodeMap();
    // Add initial point to frontier.
    _node_map[sample.start.x][sample.start.y].state = STATE_VISITED;
    _node_map[sample.start.x][sample.start.y].cost  = 0.0;
    _node_map[sample.start.x][sample.start.y].g     = 0.0;
    std::deque<StreetMap::MapPoint> open_list;
    open_list.push_back(sample.start);
    // Enter searching loop, search for path to end node until solution
    // is found (end point is close), max number of iterations are reached
    // or it is clear that no solution exists.
    uint path_index = 0; StreetMap::MapPoint current;
    for(uint i = 0; i < MAX_SEARCH_STEPS; ++i)
    {
        // Check if open list empty, then break.
        if (open_list.empty()) break;
        // Current node = min cost.
        current = open_list.front(); open_list.pop_front();
        const double current_g = _node_map[current.x][current.y].g;
        path_index++;
        // Check for breaking condition - Target in range ?
        if(StreetMap::distance(current, sample.end) < TERMINATION_DIS) break;
        // Freeze current point.
        _node_map[current.x][current.y].state = STATE_FROZEN;
        // Expand neighbours of current node.
        neighbourPoints(current, neighbours);
        for(auto& neigh : neighbours)
        {
            // Frozen nodes have already converged, skip them.
            if(_node_map[neigh.x][neigh.y].state == STATE_FROZEN) continue;
            // Compare new with previous cost.
            const double distance = StreetMap::distance(current, neigh);
            const double velocity = _street_map.velocity(neigh, sample.hour);
            const double costs = distance/velocity;
            const double g_buf = current_g + costs;
            // Check if better cost already known.
            if(_node_map[neigh.x][neigh.y].state == STATE_VISITED
                && _node_map[neigh.x][neigh.y].g <= g_buf) continue;
            // Else update pointer to previous node.
            _node_map[neigh.x][neigh.y].previous = current;
            // Else reset cost of neighbour node and update full cost f.
            _node_map[neigh.x][neigh.y].g    = g_buf;
            _node_map[neigh.x][neigh.y].cost = g_buf + heuristic(neigh, sample);
            // Prepare to expand neighbour point later, i.e. update
            // if better value for g is found or add to frontier.
            if(_node_map[neigh.x][neigh.y].state != STATE_VISITED)
            {
                _node_map[neigh.x][neigh.y].state = STATE_VISITED;
                neigh.cost = _node_map[neigh.x][neigh.y].cost;
                open_list.push_back(neigh);
            }
                // If node already is element of the frontier update cost and thus
                // the order in the open list (priority queue).
            else
            {
                for(auto it : open_list)
                {
                    if(it == neigh) it.cost = _node_map[neigh.x][neigh.y].cost;
                }
            }
        }
        // Sort queue so that smallest cost is at front.
        std::sort(open_list.begin(), open_list.end());
    }
    // Backtrack path and sum up trajectory length.
    traj_length += TERMINATION_DIS;
    path.reserve(path_index + 1);
    while(current != sample.start)
    {
        const StreetMap::MapPoint previous = _node_map[current.x][current.y].previous;
        path.push_back(previous);
        traj_length += StreetMap::distance(previous, current);
        current = previous;
    }
    // Add end point and termination distance to path length and return.
    path.push_back(sample.end);
    return traj_length;
}

double OptimalTimeSearch::closestStreetPoint(StreetMap::MapPoint& start_point)
{
    if (!_street_map.valid(start_point)) throw std::invalid_argument("Start point not in map !");
    // If street point already part of street return no distance.
    if (_street_map.boolean(start_point)) return 0.0;
    // Reset cost and state of nodes in map.
    resetNodeMap();
    // UCS cost based priority queue.
    StreetMap::MapPoint start = start_point;
    _node_map[start.x][start.y].state = STATE_VISITED;
    _node_map[start.x][start.y].cost  = 0.0;
    std::deque<StreetMap::MapPoint> open_list;
    open_list.push_back(start);
    // When the starting point not already is a street point
    // start UCS (UniformCostSearch).
    StreetMap::MapPoint current;
    for(uint i = 0; i < MAX_SEARCH_STEPS; ++i)
    {
        // Check if open list empty, then break.
        if(open_list.empty()) break;
        // Current node = min cost.
        current = open_list.front(); open_list.pop_front();
        const double current_cost = _node_map[current.x][current.y].cost;
        // Check terminal condition - Street point ?
        if(_street_map.boolean(current))
        {
            start_point = current;
            return current.cost;
        }
        // Freeze current point.
        _node_map[current.x][current.y].state = STATE_FROZEN;
        // Expand neighbours of current node.
        t_point_vector neighbours = _street_map.neighbours(current);
        for(auto& neigh : neighbours)
        {
            // Frozen nodes have already converged, skip them.
            if(_node_map[neigh.x][neigh.y].state == STATE_FROZEN) continue;
            // Compare new with previous cost.
            const double costs = current_cost + StreetMap::distance(current, neigh);
            // Check if better cost already known.
            if(_node_map[neigh.x][neigh.y].state == STATE_VISITED
                && _node_map[neigh.x][neigh.y].cost <= costs) continue;
            // Else update pointer to previous node.
            _node_map[neigh.x][neigh.y].previous = current;
            // Else reset cost of neighbour node and update full cost f.
            _node_map[neigh.x][neigh.y].cost = costs;
            // Prepare to expand neighbour point later, i.e. update
            // if better value for g is found or add to frontier.
            if(_node_map[neigh.x][neigh.y].state != STATE_VISITED)
            {
                _node_map[neigh.x][neigh.y].state = STATE_VISITED;
                neigh.cost = _node_map[neigh.x][neigh.y].cost;
                open_list.push_back(neigh);
            }
                // If node already is element of the frontier update cost and thus
                // the order in the open list (priority queue).
            else
            {
                for(auto it : open_list)
                {
                    if(it == neigh) it.cost = _node_map[neigh.x][neigh.y].cost;
                }
            }
        }
        // Sort queue so that smallest cost is at front.
        std::sort(open_list.begin(), open_list.end());
    }
    printf("%d %d\n", start_point.x, start_point.y);
    throw std::runtime_error("Failed to find closest point !");
}

double OptimalTimeSearch::heuristic(const StreetMap::MapPoint& point,
                                    const MapSet& sample) const
{
    return StreetMap::distance(point, sample.end)/HEURISTIC_MAX_VELOCITY;
}

void OptimalTimeSearch::resetNodeMap()
{
    assert(_node_map.size() != 0);
    for(int x = 0; x < _node_map.size(); ++x)
        for(int y = 0; y < _node_map[x].size(); ++y)
        {
            _node_map[x][y].cost  = 999.9;
            _node_map[x][y].state = STATE_UNKNOWN;
        }
}
