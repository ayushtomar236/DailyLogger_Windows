using System;
using System.Windows;
using System.Windows.Input;
using DailyLogger.App.ViewModels;

namespace DailyLogger.App
{
    public partial class MainWindow : Window
    {
        private readonly PromptViewModel _viewModel;

        public MainWindow(PromptViewModel viewModel)
        {
            InitializeComponent();
            _viewModel = viewModel;
            DataContext = _viewModel;

            _viewModel.RequestClose += (_, _) => Close();

            // Support Escape key anywhere in window to dismiss
            KeyDown += MainWindow_KeyDown;
        }

        private void MainWindow_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Key == Key.Escape)
            {
                if (_viewModel.IsSettingsOpen)
                {
                    _viewModel.IsSettingsOpen = false;
                }
                else
                {
                    Close();
                }
                e.Handled = true;
            }
        }

        private void PromptTextBox_KeyDown(object sender, KeyEventArgs e)
        {
            // Support Ctrl + Enter to submit
            if (e.Key == Key.Return && (Keyboard.Modifiers & ModifierKeys.Control) == ModifierKeys.Control)
            {
                if (_viewModel.CanSubmit)
                {
                    _viewModel.SaveEntry();
                }
                e.Handled = true;
            }
        }

        private void Header_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            if (e.ButtonState == MouseButtonState.Pressed)
            {
                DragMove();
            }
        }
    }
}
