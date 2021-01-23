#include "Predictor.h"

#include <algorithm>
#include <cassert>
#include <chrono>
#include <iostream>
#include <random>

Predictor::Predictor(const StreetMap& map)
    : _street_map(map)
{
    // Pre-calculate circle candidates vector;
    _circle_points.reserve(360/PHI_STEP_WIDTH);
    for (int phi = 0; phi < 360; phi += PHI_STEP_WIDTH)
    {
        const double phi_rad = M_PI / 180.0 * phi;
        StreetMap::MapPoint point(static_cast<int>(STEP_WIDTH*cos(phi_rad)),
                                  static_cast<int>(STEP_WIDTH*sin(phi_rad)));
        _circle_points.push_back(point);
    }
}

double Predictor::predict(const DataSet& sample, t_point_vector &path)
{
    // Convert sample to map points.
    MapSet sample_map(_street_map.pointToMap(sample.start),
                    _street_map.pointToMap(sample.end), sample.hour);
    // Predict trajectory length.
    const double traj_length = predictPath(sample_map, path);
    // Convert path to sample frame.
    path = _street_map.vecToData(path);
    return traj_length;
}

double Predictor::predict(const MapSet& sample, t_point_vector &path)
{
    // Copy sample to be able to change them.
    MapSet sample_map(sample.start, sample.end, sample.hour);
    // Predict trajectory length.
    const double traj_length = predictPath(sample_map, path);
    // Convert path to sample frame.
    path = _street_map.vecToData(path);
    return traj_length;
}

void Predictor::accuracy(const std::vector< DataSet >& sample_vector,
                         const std::vector<double> &true_lengths,
                         uint32_t num_samples)
{

    // Start time measurement.
    std::chrono::time_point<std::chrono::system_clock> start, end;
    start = std::chrono::system_clock::now();
    // Predict path length.
    const double pred_rmpse = predictionAccuracy(sample_vector, true_lengths, num_samples);
    end = std::chrono::system_clock::now();
    const long elapsed_seconds = std::chrono::duration_cast<std::chrono::milliseconds>(end-start).count();
    // Calculate euclidean distance for comparison issues.
    const double euc_rmpse = euclideanAccuracy(sample_vector, true_lengths, num_samples);
    // Print results.
    printf("Road Map Prediction vs Euclidean Distance prediction over %d samples\n", num_samples);
    printf("Error(RMPSE): %f vs. %f\n", pred_rmpse, euc_rmpse);
    printf("Time usage per sample: %f ms\n", (double)elapsed_seconds/TESTING_SAMPLES);
}

void Predictor::neighbourPoints(const StreetMap::MapPoint current_point,
                                t_point_vector& neighbours) const
{
    /*
    // Resize neighbours vector if necessary.
    if(neighbours.size() != _circle_points.size())
    {
        neighbours.reserve(_circle_points.size());
    }
    // Fill neighbours as new candidates, except of invalid points.
    for (const auto& circle_point : _circle_points)
    {
        const StreetMap::MapPoint neigh(current_point.x + circle_point.x,
                                        current_point.y + circle_point.y);
        if(!_street_map.valid(neigh))   continue;
        if(!_street_map.boolean(neigh)) continue;
        neighbours[index] = neigh;
        index++;
    }
    neighbours.shrink_to_fit();
    */
    neighbours.clear(); neighbours.reserve(8);
    for(int x = -1; x <= +1; ++x)
        for(int y = -1; y <= +1; ++y)
    {
        if(x == 0 && y == 0) continue;
        const StreetMap::MapPoint neigh(current_point.x + x,
                                        current_point.y + y);
        if(!_street_map.valid(neigh))   continue;
        if(!_street_map.boolean(neigh)) continue;
        neighbours.push_back(neigh);
    }
    neighbours.shrink_to_fit();
}

double Predictor::rmpse(const std::vector<double> &preds,
                        const std::vector<double> &labels) const
{
    assert(preds.size() == labels.size());
    double errors = 0.0;
    for (unsigned int i = 0; i < preds.size(); ++i) {
        errors += std::pow((preds[i] - labels[i]) / labels[i], 2);
    }
    // Calculate rmpse.
    return std::sqrt(errors/preds.size());
}

void Predictor::sampleIndex(const int num_samples, const size_t sample_size,
                            std::vector<int> &index_vector) const
{
    // Init random device for sampling.
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> dis(0, (int) sample_size);
    // Fill index vector with random indexes.
    index_vector.clear();
    index_vector.resize((unsigned long) num_samples);
    for (int k = 0; k < num_samples; ++k)  index_vector[k] = dis(gen);
}

double Predictor::predictionAccuracy(const std::vector< DataSet >& sample_vector,
                                     const std::vector<double> &true_lengths,
                                     uint32_t num_testing_samples)
{
    const unsigned long num_sample = sample_vector.size();
    assert(num_sample == true_lengths.size());
    assert(num_sample >= num_testing_samples);
    // Get random samples from sample set.
    std::vector<int> indexes;
    sampleIndex(num_testing_samples, num_sample, indexes);
    // Predict every point and measure prediction time.
    std::vector<double> predictions, true_values;
    predictions.resize(num_testing_samples);
    true_values.resize(num_testing_samples);
    for (unsigned int i = 0; i < num_testing_samples; ++i)
    {
        DataSet sample(sample_vector[indexes[i]].start,
                     sample_vector[indexes[i]].end,
                     sample_vector[indexes[i]].hour);
        t_point_vector path;
        predictions[i] = predict(sample, path);
        true_values[i] = true_lengths[indexes[i]];
    }
    return rmpse(predictions, true_values);
}

double Predictor::euclideanAccuracy(const std::vector< DataSet >& sample_vector,
                                    const std::vector<double> &true_lengths,
                                    uint32_t num_testing_samples) const
{
    const unsigned long num_sample = sample_vector.size();
    assert(num_sample == true_lengths.size());
    assert(num_sample >= num_testing_samples);
    // Get random samples from sample set.
    std::vector<int> indexes;
    sampleIndex(num_testing_samples, num_sample, indexes);
    // Predict every point using euclidean estimation.
    std::vector<double> euclideans, true_values;
    euclideans.resize(num_testing_samples);
    true_values.resize(num_testing_samples);
    for (unsigned int i = 0; i < num_testing_samples; ++i)
    {
        euclideans[i]  = StreetMap::distance(sample_vector[indexes[i]].start,
                                             sample_vector[indexes[i]].end);
        true_values[i] = true_lengths[indexes[i]];
    }
    return rmpse(euclideans, true_values);
}