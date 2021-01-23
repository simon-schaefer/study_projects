#include "CSVReader.h"

#include <algorithm>
#include <iostream>
#include <fstream>
#include <stdexcept>

CSVReader::CSVReader(const std::string& csv_file)
{
    // Open data file and create list of containing data.
    std::ifstream file(csv_file);
    if (!file)
    {
        throw std::runtime_error("Could not open file " + csv_file);
    }
    // Read first line (labels) from data and get rid of csv " . " label
    // signs for easy access later on. Drop ID, TaxiID and duration.
    std::string line; getline(file, line);
    _labels = split(line, ',');
    for (auto& label : _labels)
    {
        label.erase(0, 1);
        label.erase(label.size() - 1);
    }
    // Read other lines and write as string to list.
    while(getline(file, line))
    {
        t_string_vector vec;
        std::string symbol; bool substring = false;
        for (const auto& c : line)
        {
            if (c == '"') { substring = !substring; continue; }
            if (c == ' ') { continue;                         }
            if (c == ',' && !substring)
            {
                vec.push_back(symbol);
                symbol = "";
                continue;
            }
            symbol += c;
        }
        vec.push_back(symbol);
        _data.push_back(vec);
    }
    file.close();
    std::cout << "Read in data set successfully ! " << std::endl;
    std::cout << "Labels: ";
    for (const auto& label : _labels) std::cout << label << " ";
    std::cout << std::endl;
}

std::vector<int> CSVReader::getHours(const std::string& label) const
{
    const t_string_vector col = getColumn(label);
    std::vector<int> values;
    for (const auto& value : col)
    {
        std::string hour_string = split(value, ':')[0];
        hour_string = hour_string.substr(hour_string.length() - 2);
        double number;
        std::stringstream ss(hour_string); ss >> number;
        values.push_back((int)number);
    }
    return values;
}

void CSVReader::save(const std::string& csv_file)
{
    // Open data file to save.
    std::ofstream file(csv_file);
    // Write labels into csv file.
    for (int i = 0; i < _labels.size(); ++i)
    {
        file << _labels[i];
        if (i < _labels.size() - 1) file << ", ";
    }
    file << std::endl;
    // Write data matrix into csv file.
    for (const auto& line : _data)
    {
        std::string line_string;
        for (int i = 0; i < line.size(); ++i)
        {
            line_string += line[i];
            if (i < line.size() - 1) line_string += ", ";
        }
        file << line_string << std::endl;
    }
    file.close();
    printf("Wrote file successfully to file %s!\n", csv_file.c_str());
}

CSVReader::t_string_vector CSVReader::getColumn(const std::string& label) const
{
    auto position = std::find(_labels.begin(), _labels.end(), label);
    if(position == _labels.end())
    {
        throw std::invalid_argument(label + " not in data set !");
    }
    unsigned long index = position - _labels.begin();
    t_string_vector column;
    for (const auto& row : _data)
    {
        column.push_back(row[index]);
    }
    return column;
}

std::vector<std::string> CSVReader::split(const std::string& line,
                                          const char delimeter) const
{
    std::stringstream ss(line);
    std::string item;
    std::vector<std::string> splitted_strings;
    while (std::getline(ss, item, delimeter))
    {
        splitted_strings.push_back(item);
    }
    return splitted_strings;
}