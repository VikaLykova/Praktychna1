-- V4: індекси таблиці вимірів (за результатами аналізу плану запиту q03)
-- Складений індекс: спершу стовпці з умовою «дорівнює», останнім - діапазон часу
CREATE INDEX measurement_sensor_time_idx
  ON measurement (sensor_id, pollutant_code, measured_at);
-- BRIN: малий індекс для відбору за часом у таблиці, що лише доповнюється
CREATE INDEX measurement_time_brin
  ON measurement USING brin (measured_at);
