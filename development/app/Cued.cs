using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using System.Web.Script.Serialization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Data;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Media.Effects;
using System.Windows.Media.Animation;
using System.Windows.Shapes;
using Microsoft.Win32;

[assembly: AssemblyTitle("Cued")]
[assembly: AssemblyProduct("Cued")]
[assembly: AssemblyDescription("Playback-only speaking cards for Windows")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

namespace Cued
{
    public sealed class CueBlock
    {
        public string heading { get; set; }
        public List<string> bullets { get; set; }
    }

    public sealed class CueCard
    {
        public string id { get; set; }
        public string title { get; set; }
        public List<CueBlock> blocks { get; set; }
    }

    public sealed class CueDeck
    {
        public int schemaVersion { get; set; }
        public string title { get; set; }
        public List<CueCard> cards { get; set; }
    }

    public sealed class CueDeckWindow : Window
    {
        private const int WM_NCHITTEST = 0x0084;
        private const int WM_HOTKEY = 0x0312;
        private const int HTTRANSPARENT = -1;
        private const int HTCLIENT = 1;
        private const int HTLEFT = 10;
        private const int HTRIGHT = 11;
        private const int HTTOP = 12;
        private const int HTTOPLEFT = 13;
        private const int HTTOPRIGHT = 14;
        private const int HTBOTTOM = 15;
        private const int HTBOTTOMLEFT = 16;
        private const int HTBOTTOMRIGHT = 17;
        private const int HOTKEY_ID = 0xC0DE;
        private const uint MOD_CONTROL = 0x0002;
        private const uint VK_SPACE = 0x20;
        private const double ResizeEdge = 8.0;

        private static readonly Brush WindowBrush = BrushFrom("#FF202020");
        private static readonly Brush SurfaceBrush = BrushFrom("#FF252525");
        private static readonly Brush HoverBrush = BrushFrom("#FF343434");
        private static readonly Brush ForegroundBrush = BrushFrom("#FFF5F5F5");
        private static readonly Brush MutedBrush = BrushFrom("#FFA6A6A6");
        private static readonly Brush BorderBrushNormal = BrushFrom("#FF3A3A3A");
        private static readonly Brush BorderBrushGhost = BrushFrom("#80A6A6A6");
        private static readonly Brush ClaudeBrush = BrushFrom("#FFD97757");

        private readonly string[] _startupArgs;
        private Border _frame;
        private Grid _shell;
        private Grid _topBar;
        private Grid _landing;
        private Grid _player;
        private Border _cardSurface;
        private Border _edgeOne;
        private Border _edgeTwo;
        private Grid _cuePanel;
        private StackPanel _sectionsPanel;
        private TextBlock _cardTitle;
        private TextBlock _positionText;
        private Button _dropButton;
        private TextBlock _dropText;
        private Button _backButton;
        private Border _settingsPanel;
        private Slider _textSizeSlider;
        private Slider _ghostOpacitySlider;
        private CheckBox _reducedMotionCheck;
        private Button _ghostButton;
        private Button _settingsButton;
        private Button _openButton;
        private bool _ghostMode;
        private bool _isTransitioning;
        private bool _hotkeyRegistered;
        private int _currentIndex;
        private double _cueTextSize = 20.0;
        private double _ghostTextOpacity = 0.90;
        private CueDeck _deck;
        private HwndSource _source;
        private TranslateTransform _cardTranslate;

        [DllImport("user32.dll")]
        private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

        [DllImport("user32.dll")]
        private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

        public CueDeckWindow(string[] startupArgs)
        {
            _startupArgs = startupArgs ?? new string[0];
            Title = "Cued";
            Width = 520;
            Height = 790;
            MinWidth = 420;
            MinHeight = 620;
            WindowStartupLocation = WindowStartupLocation.CenterScreen;
            WindowStyle = WindowStyle.None;
            ResizeMode = ResizeMode.CanResize;
            AllowsTransparency = true;
            Background = Brushes.Transparent;
            Topmost = true;
            ShowInTaskbar = true;
            FontFamily = new FontFamily("Segoe UI");
            Foreground = ForegroundBrush;
            SnapsToDevicePixels = true;
            UseLayoutRounding = true;
            AllowDrop = true;

            BuildInterface();

            SourceInitialized += OnSourceInitialized;
            Closed += OnClosed;
            Loaded += OnLoaded;
            PreviewKeyDown += OnPreviewKeyDown;
            DragOver += OnDragOver;
            Drop += OnFileDrop;
        }

        private static Brush BrushFrom(string value)
        {
            return new SolidColorBrush((Color)ColorConverter.ConvertFromString(value));
        }

        private void BuildInterface()
        {
            _frame = new Border();
            _frame.Background = WindowBrush;
            _frame.BorderBrush = BorderBrushNormal;
            _frame.BorderThickness = new Thickness(1);
            _frame.CornerRadius = new CornerRadius(18);

            _shell = new Grid();
            _shell.Margin = new Thickness(10, 6, 10, 10);
            _shell.RowDefinitions.Add(new RowDefinition { Height = new GridLength(46) });
            _shell.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
            _frame.Child = _shell;
            Content = _frame;

            BuildTopBar();
            BuildLanding();
            BuildPlayer();
            BuildSettingsPanel();

            Grid.SetRow(_topBar, 0);
            Grid.SetRow(_landing, 1);
            Grid.SetRow(_player, 1);
            Grid.SetRow(_settingsPanel, 1);
            Panel.SetZIndex(_settingsPanel, 20);

            _shell.Children.Add(_topBar);
            _shell.Children.Add(_landing);
            _shell.Children.Add(_player);
            _shell.Children.Add(_settingsPanel);
            ShowLanding();
        }

        private void BuildTopBar()
        {
            _topBar = new Grid();
            _topBar.Background = Brushes.Transparent;
            _topBar.MouseEnter += delegate { if (_ghostMode) _topBar.Opacity = 1; };
            _topBar.MouseLeave += delegate { if (_ghostMode) _topBar.Opacity = 0.5; };
            _topBar.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            _topBar.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            _topBar.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            _topBar.MouseLeftButtonDown += delegate(object sender, MouseButtonEventArgs args)
            {
                if (args.ChangedButton == MouseButton.Left && args.ButtonState == MouseButtonState.Pressed)
                {
                    try { DragMove(); } catch { }
                }
            };

            _settingsButton = CreateChromeButton("⚙", "Settings");
            _settingsButton.Margin = new Thickness(2, 0, 0, 0);
            _settingsButton.Click += delegate { ToggleSettings(); };
            Grid.SetColumn(_settingsButton, 0);
            _topBar.Children.Add(_settingsButton);

            _positionText = new TextBlock();
            _positionText.Text = string.Empty;
            _positionText.FontSize = 12;
            _positionText.Foreground = MutedBrush;
            _positionText.HorizontalAlignment = HorizontalAlignment.Center;
            _positionText.VerticalAlignment = VerticalAlignment.Center;
            Grid.SetColumn(_positionText, 1);
            _topBar.Children.Add(_positionText);

            StackPanel controls = new StackPanel();
            controls.Orientation = Orientation.Horizontal;
            controls.HorizontalAlignment = HorizontalAlignment.Right;
            controls.VerticalAlignment = VerticalAlignment.Center;

            Button minimise = CreateChromeButton("—", "Minimise");
            minimise.Click += delegate { WindowState = WindowState.Minimized; };
            controls.Children.Add(minimise);

            _ghostButton = CreateChromeButton(string.Empty, "Ghost");
            _ghostButton.Width = 64;
            _ghostButton.Height = 44;
            _ghostButton.Background = Brushes.Transparent;
            _ghostButton.BorderBrush = Brushes.Transparent;
            _ghostButton.BorderThickness = new Thickness(0);
            _ghostButton.Content = CreateGhostIcon();
            _ghostButton.Click += delegate { SetGhostMode(!_ghostMode); };
            controls.Children.Add(_ghostButton);

            Button close = CreateChromeButton("×", "Close");
            close.FontSize = 19;
            close.Click += delegate { Close(); };
            controls.Children.Add(close);

            Grid.SetColumn(controls, 2);
            _topBar.Children.Add(controls);
        }

        private UIElement CreateGhostIcon()
        {
            Canvas icon = new Canvas();
            icon.Width = 28;
            icon.Height = 28;
            icon.IsHitTestVisible = true;

            System.Windows.Shapes.Path body = new System.Windows.Shapes.Path();
            body.Data = Geometry.Parse("M14,2 C7.4,2 2,7.4 2,14 L2,26 L7,21 L11.5,26 L16,21 L21,26 L26,21 L26,14 C26,7.4 20.6,2 14,2 Z");
            body.Fill = ForegroundBrush;
            icon.Children.Add(body);

            Ellipse leftEye = new Ellipse();
            leftEye.Width = 4;
            leftEye.Height = 6;
            leftEye.Fill = WindowBrush;
            Canvas.SetLeft(leftEye, 8);
            Canvas.SetTop(leftEye, 10);
            icon.Children.Add(leftEye);

            Ellipse rightEye = new Ellipse();
            rightEye.Width = 4;
            rightEye.Height = 6;
            rightEye.Fill = WindowBrush;
            Canvas.SetLeft(rightEye, 17);
            Canvas.SetTop(rightEye, 10);
            icon.Children.Add(rightEye);

            return icon;
        }

        private void BuildLanding()
        {
            _landing = new Grid();
            _landing.HorizontalAlignment = HorizontalAlignment.Center;
            _landing.VerticalAlignment = VerticalAlignment.Center;
            _landing.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(190) });
            _landing.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(2) });
            _landing.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(230) });

            _openButton = CreateLandingOpenButton();
            _openButton.Click += delegate { ChooseDeck(); };
            Grid.SetColumn(_openButton, 0);
            _landing.Children.Add(_openButton);

            Border divider = new Border();
            divider.Width = 2;
            divider.Height = 190;
            divider.VerticalAlignment = VerticalAlignment.Center;
            LinearGradientBrush dividerBrush = new LinearGradientBrush();
            dividerBrush.StartPoint = new Point(0, 0);
            dividerBrush.EndPoint = new Point(0, 1);
            dividerBrush.GradientStops.Add(new GradientStop(Color.FromArgb(0, 255, 255, 255), 0));
            dividerBrush.GradientStops.Add(new GradientStop(Color.FromArgb(145, 255, 255, 255), 0.5));
            dividerBrush.GradientStops.Add(new GradientStop(Color.FromArgb(0, 255, 255, 255), 1));
            divider.Background = dividerBrush;
            Grid.SetColumn(divider, 1);
            _landing.Children.Add(divider);

            StackPanel createPanel = new StackPanel();
            createPanel.HorizontalAlignment = HorizontalAlignment.Center;
            createPanel.VerticalAlignment = VerticalAlignment.Center;

            TextBlock createText = new TextBlock();
            createText.Text = "Create";
            createText.FontSize = 26;
            createText.FontWeight = FontWeights.SemiBold;
            createText.HorizontalAlignment = HorizontalAlignment.Center;
            createText.Margin = new Thickness(0, 0, 0, 22);
            createPanel.Children.Add(createText);

            StackPanel providerRow = new StackPanel();
            providerRow.Orientation = Orientation.Horizontal;
            providerRow.HorizontalAlignment = HorizontalAlignment.Center;

            Button openAi = CreateProviderButton(CreateOpenAiMark(), "Create with ChatGPT");
            openAi.Margin = new Thickness(0, 0, 10, 0);
            openAi.Click += delegate { OpenProvider(false); };
            providerRow.Children.Add(openAi);

            Button claude = CreateProviderButton(CreateClaudeMark(), "Create with Claude Cowork");
            claude.Margin = new Thickness(10, 0, 0, 0);
            claude.Click += delegate { OpenProvider(true); };
            providerRow.Children.Add(claude);

            createPanel.Children.Add(providerRow);
            Grid.SetColumn(createPanel, 2);
            _landing.Children.Add(createPanel);
        }

        private Button CreateLandingOpenButton()
        {
            Button button = CreateButtonBase(170, 230, 16);
            button.Background = Brushes.Transparent;
            button.BorderBrush = Brushes.Transparent;
            button.ToolTip = "Open a cue deck";

            StackPanel panel = new StackPanel();
            panel.HorizontalAlignment = HorizontalAlignment.Center;
            panel.VerticalAlignment = VerticalAlignment.Center;

            TextBlock open = new TextBlock();
            open.Text = "Open";
            open.FontSize = 26;
            open.FontWeight = FontWeights.SemiBold;
            open.HorizontalAlignment = HorizontalAlignment.Center;
            open.Margin = new Thickness(0, 0, 0, 22);
            panel.Children.Add(open);

            TextBlock folder = new TextBlock();
            folder.Text = "\uE8B7";
            folder.FontFamily = new FontFamily("Segoe Fluent Icons");
            folder.FontSize = 72;
            folder.Foreground = ForegroundBrush;
            folder.HorizontalAlignment = HorizontalAlignment.Center;
            panel.Children.Add(folder);

            button.Content = panel;
            return button;
        }

        private Button CreateProviderButton(UIElement mark, string tooltip)
        {
            Button button = CreateButtonBase(82, 82, 18);
            button.Background = SurfaceBrush;
            button.BorderBrush = BorderBrushNormal;
            button.BorderThickness = new Thickness(1);
            button.Padding = new Thickness(18);
            button.Content = mark;
            button.ToolTip = tooltip;
            return button;
        }

        private UIElement CreateOpenAiMark()
        {
            const string geometry = "M249.176 323.434V298.276C249.176 296.158 249.971 294.569 251.825 293.509L302.406 264.381C309.29 260.409 317.5 258.555 325.973 258.555C357.75 258.555 377.877 283.185 377.877 309.399C377.877 311.253 377.877 313.371 377.611 315.49L325.178 284.771C322.001 282.919 318.822 282.919 315.645 284.771L249.176 323.434ZM367.283 421.415V361.301C367.283 357.592 365.694 354.945 362.516 353.092L296.048 314.43L317.763 301.982C319.617 300.925 321.206 300.925 323.058 301.982L373.639 331.112C388.205 339.586 398.003 357.592 398.003 375.069C398.003 395.195 386.087 413.733 367.283 421.412V421.415ZM233.553 368.452L211.838 355.742C209.986 354.684 209.19 353.095 209.19 350.975V292.718C209.19 264.383 230.905 242.932 260.301 242.932C271.423 242.932 281.748 246.641 290.49 253.26L238.321 283.449C235.146 285.303 233.555 287.951 233.555 291.659V368.455L233.553 368.452ZM280.292 395.462L249.176 377.985V340.913L280.292 323.436L311.407 340.913V377.985L280.292 395.462ZM300.286 475.968C289.163 475.968 278.837 472.259 270.097 465.64L322.264 435.449C325.441 433.597 327.03 430.949 327.03 427.239V350.445L349.011 363.155C350.865 364.213 351.66 365.802 351.66 367.922V426.179C351.66 454.514 329.679 475.965 300.286 475.965V475.968ZM237.525 416.915L186.944 387.785C172.378 379.31 162.582 361.305 162.582 343.827C162.582 323.436 174.763 305.164 193.563 297.485V357.861C193.563 361.571 195.154 364.217 198.33 366.071L264.535 404.467L242.82 416.915C240.967 417.972 239.377 417.972 237.525 416.915ZM234.614 460.343C204.689 460.343 182.71 437.833 182.71 410.028C182.71 407.91 182.976 405.792 183.238 403.672L235.405 433.863C238.582 435.715 241.763 435.715 244.938 433.863L311.407 395.466V420.622C311.407 422.742 310.612 424.331 308.758 425.389L258.179 454.519C251.293 458.491 243.083 460.343 234.611 460.343H234.614ZM300.286 491.854C332.329 491.854 359.073 469.082 365.167 438.892C394.825 431.211 413.892 403.406 413.892 375.073C413.892 356.535 405.948 338.529 391.648 325.552C392.972 319.991 393.766 314.43 393.766 308.87C393.766 271.003 363.048 242.666 327.562 242.666C320.413 242.666 313.528 243.723 306.644 246.109C294.725 234.457 278.307 227.042 260.301 227.042C228.258 227.042 201.513 249.815 195.42 280.004C165.761 287.685 146.694 315.49 146.694 343.824C146.694 362.362 154.638 380.368 168.938 393.344C167.613 398.906 166.819 404.467 166.819 410.027C166.819 447.894 197.538 476.231 233.024 476.231C240.172 476.231 247.058 475.173 253.943 472.788C265.859 484.441 282.278 491.854 300.286 491.854Z";
            System.Windows.Shapes.Path path = new System.Windows.Shapes.Path();
            path.Data = Geometry.Parse(geometry);
            path.Fill = ForegroundBrush;
            path.Stretch = Stretch.Uniform;
            path.IsHitTestVisible = false;
            return path;
        }

        private UIElement CreateClaudeMark()
        {
            const string geometry = "M18.7657 62.4437L37.1822 52.1167L37.4857 51.2122L37.1822 50.7085H36.2715L33.1852 50.5208L22.6615 50.2391L13.5545 49.8636L4.70044 49.3942L2.47428 48.9248L0.399902 46.1553L0.602281 44.794L2.47428 43.5266L5.15579 43.7613L11.0754 44.1837L19.98 44.794L26.4055 45.1695L35.9679 46.1553H37.4857L37.6881 45.545L37.1822 45.1695L36.7774 44.794L27.5692 38.5508L17.6021 31.9791L12.3908 28.1769L9.60812 26.2524L8.19147 24.4686L7.58433 20.5256L10.1141 17.7091L13.5545 17.9438L14.4146 18.1785L17.9056 20.8542L25.343 26.6279L35.0572 33.7629L36.4739 34.9364L37.0443 34.5514L37.1316 34.2792L36.4739 33.1996L31.212 23.6706L25.596 13.9539L23.0663 9.91695L22.4086 7.52296C22.1538 6.51831 22.0038 5.68714 22.0038 4.65957L24.8877 0.716544L26.5067 0.200195L30.4025 0.716544L32.0215 2.12477L34.4501 7.66379L38.3458 16.3478L44.4172 28.1769L46.188 31.6975L47.1493 34.9364L47.5035 35.9222H48.1106V35.3589L48.6166 28.6933L49.5273 20.5256L50.438 10.0108L50.7415 7.05356L52.2088 3.48605L55.1433 1.56148L57.42 2.64112L59.292 5.31674L59.039 7.05356L57.926 14.2824L55.7504 25.5952L54.3337 33.1996H55.1433L56.1046 32.2138L59.9497 27.1442L66.3752 19.0704L69.2085 15.8784L72.5478 12.3579L74.6728 10.668H78.7203L81.6548 15.0804L80.3394 19.6337L76.1906 24.8911L72.7502 29.3504L67.8172 35.9595L64.7562 41.2734L65.0307 41.7118L65.7681 41.6489L76.8989 39.255L82.9197 38.1753L90.1041 36.9549L93.3422 38.457L93.6963 40.006L92.4315 43.151L84.7411 45.0287L75.7353 46.8594L62.3244 50.0164L62.1759 50.1358L62.3512 50.3958L68.399 50.9432L70.9794 51.084H77.3037L89.0922 51.9759L92.1785 53.9944L93.9999 56.4822L93.6963 58.4068L88.9404 60.8008L82.5655 59.2987L67.6401 55.7312L62.5301 54.4638H61.8217V54.8862L66.0717 59.064L73.9139 66.1051L83.6786 75.2116L84.1845 77.4648L82.9197 79.2485L81.6042 79.0608L73.0032 72.5829L69.6639 69.6726L62.1759 63.3356H61.67V63.9928L63.3902 66.5276L72.5478 80.2812L73.0032 84.5059L72.3454 85.8672L69.9675 86.7121L67.3871 86.2427L61.9735 78.6852L56.4587 70.2359L52.0064 62.6315L51.4687 62.971L48.8189 91.2654L47.6047 92.7206L44.7714 93.8002L42.3934 92.0164L41.1286 89.1061L42.3934 83.3324L43.9113 75.8219L45.1255 69.8604L46.2386 62.4437L46.9184 59.9661L46.8583 59.8003L46.3153 59.8916L40.7238 67.5603L32.2239 79.0608L25.4948 86.2427L23.8758 86.8999L21.0931 85.4447L21.3461 82.863L22.9145 80.5629L32.2239 68.7338L37.8399 61.3641L41.4594 57.1337L41.4242 56.5218L41.2244 56.5048L16.489 72.6299L12.0873 73.1932L10.1647 71.4094L10.4176 68.4991L11.3283 67.5603L18.7657 62.4437Z";
            System.Windows.Shapes.Path path = new System.Windows.Shapes.Path();
            path.Data = Geometry.Parse(geometry);
            path.Fill = ClaudeBrush;
            path.Stretch = Stretch.Uniform;
            path.IsHitTestVisible = false;
            return path;
        }

        private void BuildPlayer()
        {
            _player = new Grid();
            _player.Visibility = Visibility.Collapsed;
            _player.Margin = new Thickness(8, 0, 8, 8);

            _edgeTwo = new Border();
            _edgeTwo.Height = 14;
            _edgeTwo.Background = WindowBrush;
            _edgeTwo.BorderBrush = BrushFrom("#FF454545");
            _edgeTwo.BorderThickness = new Thickness(1);
            _edgeTwo.CornerRadius = new CornerRadius(0, 0, 9, 9);
            _edgeTwo.Margin = new Thickness(24, 0, 24, 0);
            _edgeTwo.VerticalAlignment = VerticalAlignment.Bottom;

            _edgeOne = new Border();
            _edgeOne.Height = 14;
            _edgeOne.Background = WindowBrush;
            _edgeOne.BorderBrush = BrushFrom("#FF5A5A5A");
            _edgeOne.BorderThickness = new Thickness(1);
            _edgeOne.CornerRadius = new CornerRadius(0, 0, 10, 10);
            _edgeOne.Margin = new Thickness(14, 0, 14, 10);
            _edgeOne.VerticalAlignment = VerticalAlignment.Bottom;

            _cardSurface = new Border();
            _cardSurface.Background = WindowBrush;
            _cardSurface.Margin = new Thickness(0, 0, 0, 20);
            _cardTranslate = new TranslateTransform(0, 0);
            _cardSurface.RenderTransform = _cardTranslate;

            _cuePanel = new Grid();
            _cuePanel.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            _cuePanel.RowDefinitions.Add(new RowDefinition { Height = new GridLength(1, GridUnitType.Star) });
            _cuePanel.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            _cuePanel.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            _cuePanel.Margin = new Thickness(6, 4, 6, 0);

            _cardTitle = new TextBlock();
            _cardTitle.FontSize = 28;
            _cardTitle.FontWeight = FontWeights.SemiBold;
            _cardTitle.TextWrapping = TextWrapping.Wrap;
            _cardTitle.Margin = new Thickness(8, 6, 14, 20);
            Grid.SetRow(_cardTitle, 0);
            Grid.SetColumn(_cardTitle, 0);
            _cuePanel.Children.Add(_cardTitle);

            _sectionsPanel = new StackPanel();
            _sectionsPanel.Margin = new Thickness(8, 0, 14, 0);
            Grid.SetRow(_sectionsPanel, 1);
            Grid.SetColumn(_sectionsPanel, 0);
            _cuePanel.Children.Add(_sectionsPanel);

            Grid actionRow = new Grid();
            actionRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(94) });
            actionRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            actionRow.Margin = new Thickness(0, 18, 0, 0);

            _backButton = CreateButtonBase(84, 46, 12);
            _backButton.Content = "←  Back";
            _backButton.FontSize = 14;
            _backButton.FontWeight = FontWeights.SemiBold;
            _backButton.Background = SurfaceBrush;
            _backButton.BorderBrush = BrushFrom("#FF505050");
            _backButton.BorderThickness = new Thickness(1);
            _backButton.Foreground = ForegroundBrush;
            _backButton.ToolTip = "Previous card";
            _backButton.Click += delegate { MoveTo(_currentIndex - 1, false); };
            Grid.SetColumn(_backButton, 0);
            actionRow.Children.Add(_backButton);

            _dropButton = CreateButtonBase(double.NaN, 46, 14);
            _dropButton.Background = WindowBrush;
            _dropButton.Foreground = ForegroundBrush;
            _dropButton.BorderBrush = BrushFrom("#FF5A5A5A");
            _dropButton.BorderThickness = new Thickness(1);
            _dropButton.Padding = new Thickness(16, 0, 16, 0);
            _dropButton.HorizontalAlignment = HorizontalAlignment.Stretch;
            _dropButton.HorizontalContentAlignment = HorizontalAlignment.Stretch;
            _dropButton.VerticalContentAlignment = VerticalAlignment.Stretch;
            _dropButton.Click += delegate { Advance(); };

            Grid dropContent = new Grid();
            dropContent.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            dropContent.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            _dropText = new TextBlock();
            _dropText.FontSize = 15;
            _dropText.TextTrimming = TextTrimming.CharacterEllipsis;
            _dropText.VerticalAlignment = VerticalAlignment.Center;
            dropContent.Children.Add(_dropText);
            TextBlock arrow = new TextBlock();
            arrow.Text = "↓";
            arrow.FontSize = 18;
            arrow.VerticalAlignment = VerticalAlignment.Center;
            Grid.SetColumn(arrow, 1);
            dropContent.Children.Add(arrow);
            _dropButton.Content = dropContent;
            Grid.SetColumn(_dropButton, 1);
            actionRow.Children.Add(_dropButton);

            Grid.SetRow(actionRow, 2);
            Grid.SetColumn(actionRow, 0);
            _cuePanel.Children.Add(actionRow);

            _cardSurface.Child = _cuePanel;
            _player.Children.Add(_edgeTwo);
            _player.Children.Add(_edgeOne);
            _player.Children.Add(_cardSurface);
        }

        private void BuildSettingsPanel()
        {
            _settingsPanel = new Border();
            _settingsPanel.Width = 270;
            _settingsPanel.HorizontalAlignment = HorizontalAlignment.Left;
            _settingsPanel.VerticalAlignment = VerticalAlignment.Top;
            _settingsPanel.Margin = new Thickness(0, 0, 0, 0);
            _settingsPanel.Padding = new Thickness(16);
            _settingsPanel.Background = SurfaceBrush;
            _settingsPanel.BorderBrush = BorderBrushNormal;
            _settingsPanel.BorderThickness = new Thickness(1);
            _settingsPanel.CornerRadius = new CornerRadius(14);
            _settingsPanel.Visibility = Visibility.Collapsed;

            StackPanel content = new StackPanel();
            content.Children.Add(CreateSettingLabel("Cue text"));
            _textSizeSlider = new Slider();
            _textSizeSlider.Minimum = 17;
            _textSizeSlider.Maximum = 26;
            _textSizeSlider.Value = _cueTextSize;
            _textSizeSlider.TickFrequency = 1;
            _textSizeSlider.IsSnapToTickEnabled = true;
            _textSizeSlider.Margin = new Thickness(0, 4, 0, 14);
            _textSizeSlider.ValueChanged += delegate
            {
                _cueTextSize = _textSizeSlider.Value;
                if (_deck != null) RenderCard();
            };
            content.Children.Add(_textSizeSlider);

            content.Children.Add(CreateSettingLabel("Ghost text"));
            _ghostOpacitySlider = new Slider();
            _ghostOpacitySlider.Minimum = 65;
            _ghostOpacitySlider.Maximum = 100;
            _ghostOpacitySlider.Value = _ghostTextOpacity * 100;
            _ghostOpacitySlider.TickFrequency = 5;
            _ghostOpacitySlider.IsSnapToTickEnabled = true;
            _ghostOpacitySlider.Margin = new Thickness(0, 4, 0, 14);
            _ghostOpacitySlider.ValueChanged += delegate
            {
                _ghostTextOpacity = _ghostOpacitySlider.Value / 100.0;
                if (_ghostMode) _cuePanel.Opacity = _ghostTextOpacity;
            };
            content.Children.Add(_ghostOpacitySlider);

            _reducedMotionCheck = new CheckBox();
            _reducedMotionCheck.Content = "Reduced motion";
            _reducedMotionCheck.Foreground = ForegroundBrush;
            _reducedMotionCheck.IsChecked = false;
            content.Children.Add(_reducedMotionCheck);

            TextBlock shortcut = new TextBlock();
            shortcut.Text = "Advance: Ctrl + Space";
            shortcut.Foreground = MutedBrush;
            shortcut.FontSize = 12;
            shortcut.Margin = new Thickness(0, 14, 0, 0);
            content.Children.Add(shortcut);

            _settingsPanel.Child = content;
        }

        private TextBlock CreateSettingLabel(string text)
        {
            TextBlock label = new TextBlock();
            label.Text = text;
            label.FontSize = 13;
            label.Foreground = MutedBrush;
            return label;
        }

        private Button CreateChromeButton(string text, string tooltip)
        {
            Button button = CreateButtonBase(44, 40, 10);
            button.Content = text;
            button.FontSize = 16;
            button.Background = Brushes.Transparent;
            button.BorderBrush = Brushes.Transparent;
            button.Foreground = MutedBrush;
            button.ToolTip = tooltip;
            button.Margin = new Thickness(1, 0, 1, 0);
            return button;
        }

        private Button CreateButtonBase(double width, double height, double radius)
        {
            Button button = new Button();
            if (!double.IsNaN(width)) button.Width = width;
            button.Height = height;
            button.Cursor = Cursors.Hand;
            button.Foreground = ForegroundBrush;
            button.BorderThickness = new Thickness(0);
            button.HorizontalContentAlignment = HorizontalAlignment.Center;
            button.VerticalContentAlignment = VerticalAlignment.Center;
            button.Template = CreateButtonTemplate(radius);
            return button;
        }

        private ControlTemplate CreateButtonTemplate(double radius)
        {
            ControlTemplate template = new ControlTemplate(typeof(Button));
            FrameworkElementFactory border = new FrameworkElementFactory(typeof(Border));
            border.Name = "buttonBorder";
            border.SetValue(Border.CornerRadiusProperty, new CornerRadius(radius));
            border.SetBinding(Border.BackgroundProperty, new Binding("Background") { RelativeSource = new RelativeSource(RelativeSourceMode.TemplatedParent) });
            border.SetBinding(Border.BorderBrushProperty, new Binding("BorderBrush") { RelativeSource = new RelativeSource(RelativeSourceMode.TemplatedParent) });
            border.SetBinding(Border.BorderThicknessProperty, new Binding("BorderThickness") { RelativeSource = new RelativeSource(RelativeSourceMode.TemplatedParent) });
            border.SetBinding(Border.PaddingProperty, new Binding("Padding") { RelativeSource = new RelativeSource(RelativeSourceMode.TemplatedParent) });

            FrameworkElementFactory presenter = new FrameworkElementFactory(typeof(ContentPresenter));
            presenter.SetBinding(ContentPresenter.HorizontalAlignmentProperty, new Binding("HorizontalContentAlignment") { RelativeSource = new RelativeSource(RelativeSourceMode.TemplatedParent) });
            presenter.SetBinding(ContentPresenter.VerticalAlignmentProperty, new Binding("VerticalContentAlignment") { RelativeSource = new RelativeSource(RelativeSourceMode.TemplatedParent) });
            presenter.SetBinding(ContentPresenter.ContentProperty, new Binding("Content") { RelativeSource = new RelativeSource(RelativeSourceMode.TemplatedParent) });
            presenter.SetBinding(ContentPresenter.ContentTemplateProperty, new Binding("ContentTemplate") { RelativeSource = new RelativeSource(RelativeSourceMode.TemplatedParent) });
            border.AppendChild(presenter);
            template.VisualTree = border;

            Trigger hover = new Trigger();
            hover.Property = Button.IsMouseOverProperty;
            hover.Value = true;
            hover.Setters.Add(new Setter(Button.OpacityProperty, 0.82));
            template.Triggers.Add(hover);

            Trigger pressed = new Trigger();
            pressed.Property = Button.IsPressedProperty;
            pressed.Value = true;
            pressed.Setters.Add(new Setter(Button.OpacityProperty, 0.62));
            template.Triggers.Add(pressed);
            return template;
        }

        private void ToggleSettings()
        {
            _settingsPanel.Visibility = _settingsPanel.Visibility == Visibility.Visible
                ? Visibility.Collapsed
                : Visibility.Visible;
        }

        private void OpenProvider(bool useClaude)
        {
            string appFolder = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(System.IO.Path.DirectorySeparatorChar);
            string decksFolder = System.IO.Path.Combine(appFolder, "Decks");
            Directory.CreateDirectory(decksFolder);

            string link = BuildProviderLink(useClaude, appFolder);
            string provider = useClaude ? "Claude Cowork" : "ChatGPT";

            try
            {
                Process.Start(new ProcessStartInfo(link) { UseShellExecute = true });
            }
            catch (Exception ex)
            {
                MessageBox.Show(
                    this,
                    "Cued could not open " + provider + ". Make sure its Windows desktop app is installed.\n\n" + ex.Message,
                    "Cued",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);
            }
        }

        private static string BuildProviderLink(bool useClaude, string appFolder)
        {
            string decksFolder = System.IO.Path.Combine(appFolder, "Decks");
            if (useClaude)
            {
                string prompt =
                    "Use the installed make-cued-deck skill to prepare a Cued deck. " +
                    "Use relevant context already available; otherwise ask what I am preparing for. " +
                    "Save the validated .cued.json in " + decksFolder + ". " +
                    "When finished, use authorised Windows desktop control to open " +
                    System.IO.Path.Combine(appFolder, "Cued.exe") + " with the deck path. " +
                    "If desktop control is unavailable, return the file only. Keep delivery to the skill's required single line.";
                return
                    "claude://cowork/new?q=" + Uri.EscapeDataString(prompt) +
                    "&folder=" + Uri.EscapeDataString(appFolder);
            }

            string openAiPrompt =
                "Switch this task to Work mode and GPT-5.6 Terra. " +
                "Use $make-cued-deck to prepare a Cued deck. " +
                "Ask what I am preparing for if needed. " +
                "Save the validated deck in " + decksFolder + ". " +
                "Then use authorised Windows desktop control to open " +
                System.IO.Path.Combine(appFolder, "Cued.exe") + " with the deck path.";
            return
                "codex://threads/new?prompt=" + Uri.EscapeDataString(openAiPrompt) +
                "&path=" + Uri.EscapeDataString(appFolder);
        }

        private void ChooseDeck()
        {
            OpenFileDialog dialog = new OpenFileDialog();
            dialog.Title = "Open Cued deck";
            dialog.Filter = "Cued decks (*.cued.json)|*.cued.json|Legacy cue decks (*.cue.json)|*.cue.json|JSON files (*.json)|*.json|All files (*.*)|*.*";
            dialog.Multiselect = false;
            if (dialog.ShowDialog(this) == true) LoadDeck(dialog.FileName);
        }

        private void LoadDeck(string path)
        {
            try
            {
                string json = File.ReadAllText(path);
                JavaScriptSerializer serializer = new JavaScriptSerializer();
                serializer.MaxJsonLength = 1024 * 1024;
                CueDeck parsed = serializer.Deserialize<CueDeck>(json);
                string validationError = ValidateDeck(parsed);
                if (validationError != null)
                {
                    MessageBox.Show(this, validationError, "Invalid cue deck", MessageBoxButton.OK, MessageBoxImage.Warning);
                    return;
                }

                SetGhostMode(false);
                _settingsPanel.Visibility = Visibility.Collapsed;
                _deck = parsed;
                _currentIndex = 0;
                _landing.Visibility = Visibility.Collapsed;
                _player.Visibility = Visibility.Visible;
                _ghostButton.Visibility = Visibility.Visible;
                _ghostButton.IsEnabled = true;
                RenderCard();
                Activate();
                _dropButton.Focus();
            }
            catch (Exception ex)
            {
                MessageBox.Show(this, "Could not open the cue deck.\n\n" + ex.Message, "Cued", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private string ValidateDeck(CueDeck deck)
        {
            if (deck == null) return "The file does not contain a cue deck.";
            if (deck.schemaVersion != 2) return "Unsupported schemaVersion. Cued accepts version 2.";
            if (string.IsNullOrWhiteSpace(deck.title)) return "The deck needs a title.";
            if (deck.title.Length > 120) return "The deck title must be 120 characters or fewer.";
            if (deck.cards == null || deck.cards.Count == 0) return "A deck must contain at least one card.";

            HashSet<string> ids = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            for (int cardIndex = 0; cardIndex < deck.cards.Count; cardIndex++)
            {
                CueCard card = deck.cards[cardIndex];
                int cardNumber = cardIndex + 1;
                if (card == null || string.IsNullOrWhiteSpace(card.id)) return "Card " + cardNumber + " needs an id.";
                if (!Regex.IsMatch(card.id, "^[a-z0-9]+(?:-[a-z0-9]+)*$")) return "Card " + cardNumber + " needs a kebab-case id.";
                if (!ids.Add(card.id)) return "Card ids must be unique.";
                if (string.IsNullOrWhiteSpace(card.title)) return "Card " + cardNumber + " needs a title.";
                if (CountWords(card.title) > 6) return "Card " + cardNumber + " has a title longer than six words.";
                if (card.blocks == null || card.blocks.Count != 3) return "Card " + cardNumber + " must contain exactly three heading blocks.";

                int totalWords = 0;
                for (int blockIndex = 0; blockIndex < card.blocks.Count; blockIndex++)
                {
                    CueBlock block = card.blocks[blockIndex];
                    int blockNumber = blockIndex + 1;
                    if (block == null || string.IsNullOrWhiteSpace(block.heading)) return "Card " + cardNumber + ", heading " + blockNumber + " needs a title.";
                    if (block.heading.Length > 100) return "Card " + cardNumber + ", heading " + blockNumber + " is longer than 100 characters.";
                    if (block.bullets == null || block.bullets.Count < 1 || block.bullets.Count > 3) return "Card " + cardNumber + ", heading " + blockNumber + " must contain one to three bullets.";

                    HashSet<string> bulletsSeen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                    List<string> bullets = block.bullets;
                    for (int bulletIndex = 0; bulletIndex < bullets.Count; bulletIndex++)
                    {
                        string bullet = bullets[bulletIndex];
                        if (string.IsNullOrWhiteSpace(bullet)) return "Card " + cardNumber + " contains an empty bullet.";
                        if (!bulletsSeen.Add(bullet.Trim())) return "Card " + cardNumber + ", heading " + blockNumber + " contains a duplicate bullet.";
                        int bulletWords = CountWords(bullet);
                        if (bulletWords > 12) return "Card " + cardNumber + " contains a bullet longer than 12 words.";
                        totalWords += bulletWords;
                    }
                }
                if (totalWords > 60) return "Card " + cardNumber + " contains more than 60 cue words.";
            }
            return null;
        }

        private static int CountWords(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return 0;
            return Regex.Matches(value, "[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*").Count;
        }

        private void RenderCard()
        {
            if (_deck == null || _deck.cards == null || _deck.cards.Count == 0) return;
            CueCard card = _deck.cards[_currentIndex];
            _cardTitle.Text = card.title;
            _sectionsPanel.Children.Clear();

            for (int i = 0; i < card.blocks.Count; i++)
            {
                CueBlock block = card.blocks[i];
                List<string> bullets = block.bullets;

                TextBlock heading = new TextBlock();
                heading.Text = block.heading;
                heading.FontSize = Math.Max(16, _cueTextSize - 1);
                heading.FontWeight = FontWeights.SemiBold;
                heading.Margin = new Thickness(0, 0, 0, 7);
                _sectionsPanel.Children.Add(heading);

                for (int bulletIndex = 0; bulletIndex < bullets.Count; bulletIndex++)
                {
                    Grid bulletRow = new Grid();
                    bulletRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(22) });
                    bulletRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
                    bulletRow.Margin = new Thickness(0, 0, 0, 7);

                    TextBlock bulletMark = new TextBlock();
                    bulletMark.Text = "\u2022";
                    bulletMark.FontSize = _cueTextSize;
                    bulletMark.VerticalAlignment = VerticalAlignment.Top;
                    bulletRow.Children.Add(bulletMark);

                    TextBlock bulletText = new TextBlock();
                    bulletText.Text = bullets[bulletIndex];
                    bulletText.FontSize = _cueTextSize;
                    bulletText.TextWrapping = TextWrapping.Wrap;
                    bulletText.LineHeight = _cueTextSize * 1.32;
                    Grid.SetColumn(bulletText, 1);
                    bulletRow.Children.Add(bulletText);
                    _sectionsPanel.Children.Add(bulletRow);
                }

                if (i < card.blocks.Count - 1)
                {
                    Border gap = new Border();
                    gap.Height = 10;
                    _sectionsPanel.Children.Add(gap);
                }
            }

            _positionText.Text = (_currentIndex + 1) + " / " + _deck.cards.Count;
            bool finalCard = _currentIndex == _deck.cards.Count - 1;
            _dropText.Text = finalCard ? "Finish deck" : "Next: " + _deck.cards[_currentIndex + 1].title;
            _backButton.IsEnabled = _currentIndex > 0;
            _edgeOne.Visibility = finalCard || _ghostMode ? Visibility.Collapsed : Visibility.Visible;
            _edgeTwo.Visibility = finalCard || _ghostMode ? Visibility.Collapsed : Visibility.Visible;
        }

        private void Advance()
        {
            if (_deck == null) return;
            if (_currentIndex >= _deck.cards.Count - 1)
            {
                ShowLanding();
                return;
            }
            MoveTo(_currentIndex + 1, true);
        }

        private void MoveTo(int index, bool animate)
        {
            if (_deck == null || _isTransitioning) return;
            int bounded = Math.Max(0, Math.Min(_deck.cards.Count - 1, index));
            if (bounded == _currentIndex) return;

            bool reduced = _reducedMotionCheck != null && _reducedMotionCheck.IsChecked == true;
            if (!animate || reduced)
            {
                _currentIndex = bounded;
                RenderCard();
                return;
            }

            _isTransitioning = true;
            _dropButton.IsEnabled = false;
            Duration outDuration = new Duration(TimeSpan.FromMilliseconds(125));
            QuadraticEase easeIn = new QuadraticEase { EasingMode = EasingMode.EaseIn };
            DoubleAnimation dropOut = new DoubleAnimation(0, 42, outDuration) { EasingFunction = easeIn };
            DoubleAnimation fadeOut = new DoubleAnimation(1, 0, outDuration) { EasingFunction = easeIn };
            fadeOut.Completed += delegate
            {
                _currentIndex = bounded;
                RenderCard();
                _cardTranslate.BeginAnimation(TranslateTransform.YProperty, null);
                _cardSurface.BeginAnimation(UIElement.OpacityProperty, null);
                _cardTranslate.Y = -10;
                _cardSurface.Opacity = 0.25;

                Duration inDuration = new Duration(TimeSpan.FromMilliseconds(145));
                QuadraticEase easeOut = new QuadraticEase { EasingMode = EasingMode.EaseOut };
                DoubleAnimation riseIn = new DoubleAnimation(-10, 0, inDuration) { EasingFunction = easeOut };
                DoubleAnimation fadeIn = new DoubleAnimation(0.25, 1, inDuration) { EasingFunction = easeOut };
                fadeIn.Completed += delegate
                {
                    _cardTranslate.BeginAnimation(TranslateTransform.YProperty, null);
                    _cardSurface.BeginAnimation(UIElement.OpacityProperty, null);
                    _cardTranslate.Y = 0;
                    _cardSurface.Opacity = 1;
                    _dropButton.IsEnabled = true;
                    _isTransitioning = false;
                    _dropButton.Focus();
                };
                _cardTranslate.BeginAnimation(TranslateTransform.YProperty, riseIn);
                _cardSurface.BeginAnimation(UIElement.OpacityProperty, fadeIn);
            };
            _cardTranslate.BeginAnimation(TranslateTransform.YProperty, dropOut);
            _cardSurface.BeginAnimation(UIElement.OpacityProperty, fadeOut);
        }

        private void ShowLanding()
        {
            SetGhostMode(false);
            _deck = null;
            _currentIndex = 0;
            _positionText.Text = string.Empty;
            _settingsPanel.Visibility = Visibility.Collapsed;
            _player.Visibility = Visibility.Collapsed;
            _landing.Visibility = Visibility.Visible;
            _ghostButton.IsEnabled = true;
            _ghostButton.Visibility = Visibility.Visible;
        }

        private void SetGhostMode(bool enabled)
        {
            _ghostMode = enabled;
            if (enabled)
            {
                _frame.Background = Brushes.Transparent;
                _frame.BorderBrush = BorderBrushGhost;
                _cardSurface.Background = Brushes.Transparent;
                _topBar.Opacity = 0.5;
                _dropButton.Opacity = 0.5;
                _backButton.Opacity = 0.5;
                _cuePanel.Opacity = _ghostTextOpacity;
                _landing.Opacity = _ghostTextOpacity;
                _cuePanel.Effect = new DropShadowEffect
                {
                    Color = Colors.Black,
                    BlurRadius = 5,
                    Direction = 315,
                    ShadowDepth = 1,
                    Opacity = 1
                };
                _edgeOne.Visibility = Visibility.Collapsed;
                _edgeTwo.Visibility = Visibility.Collapsed;
                _ghostButton.Foreground = ForegroundBrush;
            }
            else
            {
                _frame.Background = WindowBrush;
                _frame.BorderBrush = BorderBrushNormal;
                _cardSurface.Background = WindowBrush;
                _topBar.Opacity = 1;
                _dropButton.Opacity = 1;
                _backButton.Opacity = 1;
                _cuePanel.Opacity = 1;
                _landing.Opacity = 1;
                _cuePanel.Effect = null;
                _ghostButton.Foreground = MutedBrush;
                if (_deck != null) RenderCard();
            }
        }

        private void OnPreviewKeyDown(object sender, KeyEventArgs args)
        {
            if (_deck == null) return;
            if (args.Key == Key.Space && !(Keyboard.FocusedElement is Slider))
            {
                Advance();
                args.Handled = true;
            }
            else if (args.Key == Key.Left)
            {
                MoveTo(_currentIndex - 1, false);
                args.Handled = true;
            }
            else if (args.Key == Key.Right)
            {
                MoveTo(_currentIndex + 1, false);
                args.Handled = true;
            }
        }

        private void OnDragOver(object sender, DragEventArgs args)
        {
            args.Effects = DragDropEffects.None;
            if (args.Data.GetDataPresent(DataFormats.FileDrop))
            {
                string[] files = args.Data.GetData(DataFormats.FileDrop) as string[];
                if (files != null && files.Length == 1) args.Effects = DragDropEffects.Copy;
            }
            args.Handled = true;
        }

        private void OnFileDrop(object sender, DragEventArgs args)
        {
            string[] files = args.Data.GetData(DataFormats.FileDrop) as string[];
            if (files != null && files.Length == 1) LoadDeck(files[0]);
        }

        private void OnLoaded(object sender, RoutedEventArgs args)
        {
            if (_startupArgs.Length > 0 && File.Exists(_startupArgs[0])) LoadDeck(_startupArgs[0]);
        }

        private void OnSourceInitialized(object sender, EventArgs args)
        {
            IntPtr handle = new WindowInteropHelper(this).Handle;
            _source = HwndSource.FromHwnd(handle);
            if (_source != null) _source.AddHook(WndProc);
            _hotkeyRegistered = RegisterHotKey(handle, HOTKEY_ID, MOD_CONTROL, VK_SPACE);
        }

        private void OnClosed(object sender, EventArgs args)
        {
            IntPtr handle = new WindowInteropHelper(this).Handle;
            if (_hotkeyRegistered) UnregisterHotKey(handle, HOTKEY_ID);
            if (_source != null) _source.RemoveHook(WndProc);
        }

        private IntPtr WndProc(IntPtr hwnd, int message, IntPtr wParam, IntPtr lParam, ref bool handled)
        {
            if (message == WM_HOTKEY && wParam.ToInt32() == HOTKEY_ID)
            {
                if (_deck != null) Dispatcher.BeginInvoke(new Action(Advance));
                handled = true;
                return IntPtr.Zero;
            }

            if (message == WM_NCHITTEST)
            {
                int packed = lParam.ToInt32();
                int screenX = (short)(packed & 0xFFFF);
                int screenY = (short)((packed >> 16) & 0xFFFF);
                Point point = PointFromScreen(new Point(screenX, screenY));
                int resizeHit = HitTestResize(point);
                if (resizeHit != HTCLIENT)
                {
                    handled = true;
                    return new IntPtr(resizeHit);
                }

                if (_ghostMode)
                {
                    bool interactive = IsPointInside(_topBar, point)
                        || IsPointInside(_dropButton, point)
                        || IsPointInside(_backButton, point)
                        || (_deck == null && IsPointInside(_landing, point))
                        || (_settingsPanel.Visibility == Visibility.Visible && IsPointInside(_settingsPanel, point));
                    handled = true;
                    return new IntPtr(interactive ? HTCLIENT : HTTRANSPARENT);
                }
            }
            return IntPtr.Zero;
        }

        private int HitTestResize(Point point)
        {
            bool left = point.X >= 0 && point.X <= ResizeEdge;
            bool right = point.X <= ActualWidth && point.X >= ActualWidth - ResizeEdge;
            bool top = point.Y >= 0 && point.Y <= ResizeEdge;
            bool bottom = point.Y <= ActualHeight && point.Y >= ActualHeight - ResizeEdge;
            if (left && top) return HTTOPLEFT;
            if (right && top) return HTTOPRIGHT;
            if (left && bottom) return HTBOTTOMLEFT;
            if (right && bottom) return HTBOTTOMRIGHT;
            if (left) return HTLEFT;
            if (right) return HTRIGHT;
            if (top) return HTTOP;
            if (bottom) return HTBOTTOM;
            return HTCLIENT;
        }

        private bool IsPointInside(FrameworkElement element, Point windowPoint)
        {
            if (element == null || element.Visibility != Visibility.Visible || !element.IsEnabled) return false;
            try
            {
                Point origin = element.TranslatePoint(new Point(0, 0), this);
                Rect bounds = new Rect(origin, new Size(element.ActualWidth, element.ActualHeight));
                return bounds.Contains(windowPoint);
            }
            catch
            {
                return false;
            }
        }
    }

    public static class Program
    {
        [STAThread]
        public static void Main(string[] args)
        {
            Application app = new Application();
            app.ShutdownMode = ShutdownMode.OnMainWindowClose;
            app.Run(new CueDeckWindow(args));
        }
    }
}
