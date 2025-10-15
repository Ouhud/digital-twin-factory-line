function ros_publish(kpi, varargin)
% ROS_PUBLISH  Publiziert KPI an ROS/ROS2 (Robotics/ROS Toolbox erforderlich)
%
% ros_publish(kpi, 'useROS2',true, 'nodeName','/dtwin', ...
%                    'topic','/dtwin/kpi', 'domain',0, ...
%                    'msgType','std_msgs/Float64MultiArray', ...
%                    'dryRun',false)
%
% Felder in kpi (typisch aus kpi_finalize):
%   picked, placed, pickMiss, successRate, throughputPM, outputRatePS,
%   availability, util_robot(1x3), util_machine(1x2)
%
% Doku:
%   ROS 2 Publisher/Message in MATLAB (ros2publisher, ros2message).  [oai_citation:0‡mathworks.com](https://www.mathworks.com/help/ros/ref/ros2publisher.html?utm_source=chatgpt.com)
%   ROS (1) Publisher/Message (rospublisher, rosmessage).  [oai_citation:1‡mathworks.com](https://www.mathworks.com/help/ros/ref/publisher.html?utm_source=chatgpt.com)

p = inputParser;
addParameter(p,'useROS2',true);
addParameter(p,'nodeName','/dtwin');
addParameter(p,'topic','/dtwin/kpi');
addParameter(p,'domain',0); % ROS2 DOMAIN_ID
addParameter(p,'msgType','std_msgs/Float64MultiArray'); % od. 'std_msgs/String'
addParameter(p,'dryRun',false);
parse(p, varargin{:});
opt = p.Results;

% Toolbox-Check
hasROS = license('test','ROS_Toolbox') || license('test','Robotics_System_Toolbox');
if ~hasROS
    warning('ros_publish: Keine ROS/Robotics Toolbox-Lizenz gefunden -> DryRun');
    opt.dryRun = true;
end

% Daten als Vektor + Labels
vals = [ ...
    safe(kpi,'picked'), safe(kpi,'placed'), safe(kpi,'pickMiss'), ...
    safe(kpi,'successRate'), safe(kpi,'throughputPM'), safe(kpi,'outputRatePS'), ...
    safe(kpi,'availability'), vecget(kpi,'util_robot',1), vecget(kpi,'util_robot',2), vecget(kpi,'util_robot',3), ...
    vecget(kpi,'util_machine',1), vecget(kpi,'util_machine',2) ...
];
labels = {'picked','placed','missed','success','thr_pm','rate_ps','avail', ...
          'uR1','uR2','uR3','uM1','uM2'};

if opt.dryRun
    fprintf('[ROS] DRYRUN topic=%s msgType=%s: [%s]\n', opt.topic, opt.msgType, num2str(vals));
    return;
end

if opt.useROS2
    % -------- ROS2 -----------
    % Node & Publisher
    try
        % Node erzeugen (Domain optional über ENV)
        setenv('ROS_DOMAIN_ID', num2str(opt.domain));
        node = ros2node(opt.nodeName); %#ok<NASGU>
    catch
        % wenn schon vorhanden, ignoriere
    end
    pub = ros2publisher(opt.nodeName, opt.topic, opt.msgType);  % ros2publisher Doku.  [oai_citation:2‡mathworks.com](https://www.mathworks.com/help/ros/ref/ros2publisher.html?utm_source=chatgpt.com)
    msg = ros2message(pub);                                     % ros2message Doku.  [oai_citation:3‡mathworks.com](https://www.mathworks.com/help/ros/ref/ros2message.html?utm_source=chatgpt.com)

    switch opt.msgType
        case 'std_msgs/Float64MultiArray'
            msg.data = vals; %#ok<STRNU>
        case 'std_msgs/String'
            msg.data = sprintf('KPI: %s | %s', strjoin(labels,','), num2str(vals)); %#ok<STRNU>
        otherwise
            error('ros_publish: Unbekannter msgType für ROS2: %s', opt.msgType);
    end

    send(pub, msg);                                             % ros2publisher.send.  [oai_citation:4‡mathworks.com](https://www.mathworks.com/help/ros/ref/ros2publisher.send.html?utm_source=chatgpt.com)

else
    % -------- ROS (ROS1) -----------
    try
        % roscore annehmen (oder extern), ggf. rosinit('http://host:11311')
        if isempty(rosdevice) %#ok<ROSDV>
            % rosinit ohne Argumente versucht lokale Master-Session
            rosinit;                                           % Überblick ROS in MATLAB.  [oai_citation:5‡mathworks.com](https://www.mathworks.com/help/ros/ros-in-matlab.html?utm_source=chatgpt.com)
        end
    catch
        % evtl. bereits initialisiert
    end
    pub = rospublisher(opt.topic, opt.msgType);                 % rospublisher.  [oai_citation:6‡mathworks.com](https://www.mathworks.com/help/ros/ref/publisher.html?utm_source=chatgpt.com)
    msg = rosmessage(pub);                                      % rosmessage.  [oai_citation:7‡mathworks.com](https://www.mathworks.com/help/ros/ref/rosmessage.html?utm_source=chatgpt.com)

    switch opt.msgType
        case 'std_msgs/Float64MultiArray'
            msg.Data = vals;
        case 'std_msgs/String'
            msg.Data = sprintf('KPI: %s | %s', strjoin(labels,','), num2str(vals));
        otherwise
            error('ros_publish: Unbekannter msgType für ROS1: %s', opt.msgType);
    end
    send(pub, msg);                                             % Publish/Send.  [oai_citation:8‡mathworks.com](https://www.mathworks.com/help/ros/ug/exchange-data-with-ros-publishers-and-subscribers.html?utm_source=chatgpt.com)
end
end

% --- Helper ---
function x = safe(S,f); if isfield(S,f), x = double(S.(f)); else, x = 0; end; end
function v = vecget(S,f,i)
if isfield(S,f) && numel(S.(f))>=i, v = double(S.(f)(i));
else, v = 0; end
end