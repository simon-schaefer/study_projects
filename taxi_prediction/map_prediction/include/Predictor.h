#ifndef MAP_PREDICTION_PREDICTOR_H
#define MAP_PREDICTION_PREDICTOR_H

#include <cstdint>
#include <vector>

#include "StreetMap.h"
#include "Utilities.h"

class Predictor
{
protected:

    typedef std::vector<StreetMap::MapPoint> t_point_vector;

    StreetMap _street_map;
    t_point_vector _circle_points;

    constexpr static int STEP_WIDTH       = 5;
    constexpr static int TERMINATION_DIS  = 10;
    constexpr static int PHI_STEP_WIDTH   = 2;

    const static uint32_t TESTING_SAMPLES = 50000;

public:

    explicit Predictor(const StreetMap& map);

    double predict(const DataSet& data, t_point_vector &path);

    double predict(const MapSet& data, t_point_vector &path);

    void accuracy(const std::vector< DataSet >& data_vector,
                  const std::vector<double> &true_lengths,
                  uint32_t num_samples = TESTING_SAMPLES);

protected:

    virtual double predictPath(MapSet& sample, t_point_vector &path) = 0;

    virtual void neighbourPoints(StreetMap::MapPoint current_point,
                                 t_point_vector& neighbours) const;

    double rmpse(const std::vector<double> &preds,
                 const std::vector<double> &labels) const;

    void sampleIndex(int num_samples, size_t sample_size,
                     std::vector<int> &index_vector) const;

    double predictionAccuracy(const std::vector< DataSet >& sample_vector,
                              const std::vector<double> &true_lengths,
                              uint32_t num_testing_samples = TESTING_SAMPLES);
    double euclideanAccuracy(const std::vector< DataSet >& sample_vector,
                             const std::vector<double> &true_lengths,
                             uint32_t num_testing_samples = TESTING_SAMPLES) const;
};

#endif //MAP_PREDICTION_PREDICTOR_H
