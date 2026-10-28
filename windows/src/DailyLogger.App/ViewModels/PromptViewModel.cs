using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Windows;
using System.Windows.Input;
using DailyLogger.App.Models;
using DailyLogger.App.Services;

namespace DailyLogger.App.ViewModels
{
    public class PromptViewModel : INotifyPropertyChanged
    {
        private readonly LogService _logService;
        private readonly TaskSchedulerService _schedulerService;

        private string _entryText = string.Empty;
        private string _targetDateString = string.Empty;
        private bool _isSubmitting;
        private string? _errorMessage;
        private bool _isHistoryMode;
        private bool _isSettingsOpen;
        private int _scheduleHour = 2;
        private int _scheduleMinute = 0;

        public event PropertyChangedEventHandler? PropertyChanged;
        public event EventHandler? RequestClose;

        public ObservableCollection<LogRecord> RecentLogs { get; } = new();

        public string EntryText
        {
            get => _entryText;
            set
            {
                if (_entryText != value)
                {
                    _entryText = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(CanSubmit));
                    OnPropertyChanged(nameof(ShowPlaceholder));
                }
            }
        }

        public string TargetDateString
        {
            get => _targetDateString;
            set { _targetDateString = value; OnPropertyChanged(); }
        }

        public bool IsSubmitting
        {
            get => _isSubmitting;
            set { _isSubmitting = value; OnPropertyChanged(); OnPropertyChanged(nameof(CanSubmit)); }
        }

        public string? ErrorMessage
        {
            get => _errorMessage;
            set { _errorMessage = value; OnPropertyChanged(); OnPropertyChanged(nameof(HasError)); }
        }

        public bool HasError => !string.IsNullOrEmpty(_errorMessage);

        public bool IsHistoryMode
        {
            get => _isHistoryMode;
            set
            {
                if (_isHistoryMode != value)
                {
                    _isHistoryMode = value;
                    OnPropertyChanged();
                    OnPropertyChanged(nameof(ModeToggleText));
                    if (_isHistoryMode)
                    {
                        LoadHistory();
                    }
                }
            }
        }

        public string ModeToggleText => _isHistoryMode ? "Prompt" : "History";

        public bool ShowPlaceholder => string.IsNullOrEmpty(_entryText);

        public bool CanSubmit => !string.IsNullOrWhiteSpace(_entryText) && !_isSubmitting;

        public bool IsSettingsOpen
        {
            get => _isSettingsOpen;
            set { _isSettingsOpen = value; OnPropertyChanged(); }
        }

        public int ScheduleHour
        {
            get => _scheduleHour;
            set { _scheduleHour = Math.Clamp(value, 0, 23); OnPropertyChanged(); }
        }

        public int ScheduleMinute
        {
            get => _scheduleMinute;
            set { _scheduleMinute = Math.Clamp(value, 0, 59); OnPropertyChanged(); }
        }

        public ICommand SaveCommand { get; }
        public ICommand DismissCommand { get; }
        public ICommand ToggleModeCommand { get; }
        public ICommand ToggleSettingsCommand { get; }
        public ICommand SaveSettingsCommand { get; }

        public PromptViewModel(LogService logService, TaskSchedulerService schedulerService)
        {
            _logService = logService;
            _schedulerService = schedulerService;

            TargetDateString = _logService.CalculateLogicalDate();

            var config = _schedulerService.LoadConfig();
            ScheduleHour = config.Hour;
            ScheduleMinute = config.Minute;

            SaveCommand = new RelayCommand(_ => SaveEntry(), _ => CanSubmit);
            DismissCommand = new RelayCommand(_ => RequestClose?.Invoke(this, EventArgs.Empty));
            ToggleModeCommand = new RelayCommand(_ => IsHistoryMode = !IsHistoryMode);
            ToggleSettingsCommand = new RelayCommand(_ => IsSettingsOpen = !IsSettingsOpen);
            SaveSettingsCommand = new RelayCommand(_ => SaveSchedule());

            LoadHistory();
        }

        public void LoadHistory()
        {
            RecentLogs.Clear();
            var logs = _logService.GetRecentLogs(5);
            foreach (var log in logs)
            {
                RecentLogs.Add(log);
            }
        }

        public void SaveEntry()
        {
            var text = _entryText.Trim();
            if (string.IsNullOrWhiteSpace(text)) return;

            IsSubmitting = true;
            ErrorMessage = null;

            try
            {
                _logService.AppendLog(text);
                IsSubmitting = false;
                RequestClose?.Invoke(this, EventArgs.Empty);
            }
            catch (Exception ex)
            {
                IsSubmitting = false;
                ErrorMessage = $"Save failed: {ex.Message}";
            }
        }

        public void SaveSchedule()
        {
            try
            {
                _schedulerService.RegisterTask(ScheduleHour, ScheduleMinute);
                IsSettingsOpen = false;
            }
            catch (Exception ex)
            {
                ErrorMessage = $"Schedule failed: {ex.Message}";
            }
        }

        private void OnPropertyChanged([CallerMemberName] string? name = null)
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        }
    }

    public class RelayCommand : ICommand
    {
        private readonly Action<object?> _execute;
        private readonly Predicate<object?>? _canExecute;

        public RelayCommand(Action<object?> execute, Predicate<object?>? canExecute = null)
        {
            _execute = execute ?? throw new ArgumentNullException(nameof(execute));
            _canExecute = canExecute;
        }

        public bool CanExecute(object? parameter) => _canExecute?.Invoke(parameter) ?? true;
        public void Execute(object? parameter) => _execute(parameter);
        public event EventHandler? CanExecuteChanged
        {
            add => CommandManager.RequerySuggested += value;
            remove => CommandManager.RequerySuggested -= value;
        }
    }
}
