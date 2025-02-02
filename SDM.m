clear
clc

%% Step 2: Import data
% Reading excel file
% file_path = 'C:\Users\zohaa\OneDrive\Desktop\CS Project\8-PAM';
% clear
% clc

%% Step 2: Import data
% Amplitude Variation: The amplitude values associated with each time point vary. This variation indicates that the signal has dynamic behavior or possibly noise present within it.
% There are points where the amplitude transitions from positive to negative values and vice versa. These zero-crossings could be indicative of specific events or transitions in the signal.
% Smoothness:While the data may not be perfectly smooth due to possible noise or measurement errors, there's a general trend of gradual changes in the amplitude values over time.
% The amplitude values range from negative to positive, indicating both positive and negative excursions from the zero baseline.

% Reading excel file
file_path = 'C:\Users\zohaa\OneDrive\Desktop\Communication Systems\8-PAM';
data = xlsread(file_path);
time = data(:, 1)';
input_signal = data(:, 2);

% Plots
figure;
subplot(3, 1, 1);
plot(time, input_signal);
xlabel('Time (s)');
ylabel('Amplitude');
title('Figure 1: Input Analog Wave');

%% Step 3: SDM-based ADC
% Oversampling
duration = 0.000085332682292; % Duration of the sine wave signal (in seconds)
sampling_rate = 1536000000; % Sampling rate (in Hz)
oversampling_factor = 64; % Oversampling ratio
time = linspace(0, duration, duration * sampling_rate + 1);
time_oversampled = interp(time, oversampling_factor);
input_oversampled = interp(input_signal, oversampling_factor);

% Matrix of indexes of values that are negative. Taking absolute of negative
% values.
neg = find(input_oversampled < 0);
for i = 2:length(input_oversampled)
    if input_oversampled(i - 1) * input_oversampled(i) < 0
        input_oversampled(i) = -input_oversampled(i);
    end
end

% SDM parameters
sigma = 0; % Initial value for the sigma accumulator
previous_output = 0; % Initial value for the previous output

% Quantizing the difference between the input signal and the output signal
output_signal = zeros(size(input_oversampled));
delta = zeros(size(input_oversampled));
for i = 1:length(input_oversampled)
    % Compute the difference between input and previous output
    delta(i) = input_oversampled(i) - previous_output;
    % Update the sigma accumulator
    sigma = sigma + delta(i);
    % Quantize the sigma value
    if sigma >= 0
        output_signal(i) = 1;
    else
        output_signal(i) = 0;
    end
    % Feeding back the quantization error through a feedback loop
    previous_output = output_signal(i);
end

% MAT file
filename = 'zohaayeshawajihaInput.mat';
save(filename, 'output_signal');

%% Step 4: SDM-based ADC Plot
subplot(3, 1, 2);
plot(time_oversampled, output_signal);
xlabel('Time (s)');
ylabel('Digital Output');
title('Figure 2: Output of Sigma-Delta Modulation');

%% Step 5: SDM-based DAC
% Perform SDM for DAC
restored_signal = zeros(size(output_signal));
for i = 1:length(output_signal)
    restored_signal(length(output_signal) - i + 1) = delta(length(output_signal) - i + 1) + output_signal(length(output_signal) - i + 1);
end

% Filtering with window size 50
num = (1/50) * ones(1, 50);
den = [1];
restored_signal = filter(num, den, restored_signal);
restored_signal(neg) = -restored_signal(neg);

% MAT file
filename = 'zohaayeshawajihaOutput.mat';
save(filename, 'output_signal');

%% Step 6: SDM-based DAC Plot
subplot(3, 1, 3);
plot(time_oversampled, restored_signal);
xlabel('Time (s)');
ylabel('Amplitude');
title('Figure 3: Restored Analog Wave');

%% Step 7: RMS Value of Quantization Error
error_signal = restored_signal - input_oversampled;
squared_error = error_signal.^2;
mean_squared_error = mean(squared_error);
RMS_error = sqrt(mean_squared_error);
fprintf('The RMS value is:  %f\n', RMS_error);
