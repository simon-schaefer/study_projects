#ifndef MAP_PREDICTION_CSV_READER_H
#define MAP_PREDICTION_CSV_READER_H

#include <sstream>
#include <string>
#include <vector>

class CSVReader
{
    typedef std::vector<std::string>    t_string_vector;

    t_string_vector                     _labels;
    std::vector<t_string_vector>        _data;

public:

    explicit CSVReader(const std::string& csv_file);

    std::vector<int> getHours(const std::string& label) const;
    template <class T>
    std::vector<T> getTypeVector(const std::string& label) const;
    template <class T>
    std::vector<std::vector<T> > getArrayVector(const std::string& label) const;

    template <class T>
    void addTypeVector(const std::string& label, const std::vector<T>& column);
    template <class T>
    void addArrayVector(const std::string& label, const std::vector<std::vector<T> >& matrix);

    void save(const std::string& csv_file);

private:

    t_string_vector getColumn(const std::string& label) const;

    std::vector<std::string> split(const std::string& line,
                                   char delimeter) const;

};

template <class T>
std::vector<T> CSVReader::getTypeVector(const std::string& label) const
{
    const t_string_vector col = getColumn(label);
    std::vector<T> values;
    for (const auto& value : col)
    {
        double number;
        std::stringstream ss(value); ss >> number;
        values.push_back((T)number);
    }
    return values;
}

template <class T>
std::vector<std::vector<T> > CSVReader::getArrayVector(const std::string& label) const
{
    const t_string_vector col = getColumn(label);
    std::vector<std::vector<T> > values_vector;
    for (const auto& value_line : col)
    {
        t_string_vector vec;
        vec = split(value_line, ',');
        std::vector<T> values;
        for (const auto& value : vec)
        {
            double number;
            std::stringstream ss(value); ss >> number;
            values.push_back((T)number);
        }
        values_vector.push_back(values);
    }
    return values_vector;
}

template <class T>
void CSVReader::addTypeVector(const std::string& label, const std::vector<T>& column)
{
    for (int i = 0; i < column.size(); ++i)
    {
        const std::string x_string = std::to_string(column[i]);
        _data[i].push_back(x_string);
    }
    _labels.push_back(label);
}

template <class T>
void CSVReader::addArrayVector(const std::string& label, const std::vector<std::vector<T> >& matrix)
{
    for (int i = 0; i < matrix.size(); ++i)
    {
        std::string row_string;
        row_string.push_back('"');
        for (int j = 0; j < matrix[i].size(); ++j)
        {
            row_string += std::to_string(matrix[i][j]);
            if (j < matrix[i].size() - 1) row_string += ", ";
        }
        row_string.push_back('"');
        _data[i].push_back(row_string);
    }
    _labels.push_back(label);
}

#endif //MAP_PREDICTION_CSV_READER_H
