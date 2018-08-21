%%
robot = makeKukaR820();

n = robot.dof;
q = zeros(n,1);
T = zeros(4,4,n);
for i = 1:n
    T(:,:,i) = solveForwardKinematics(q(1:i), robot.A(:,1:i), robot.M(:,:,1:i));
end

%% STL Load
fv_base = stlread(['link_0.STL']);  % base link
fv_base.vertices = (T(1:3,1:3,1)*fv_base.vertices' + T(1:3,4,1)*ones(1,size(fv_base.vertices,1)))';

for i = 1:n
    fv_zero{i} = stlread(['link_' num2str(i) '.STL']);
end

fv = fv_zero;
for i = 1:n
    fv{i}.vertices = (T(1:3,1:3,i)*fv{i}.vertices' + T(1:3,4,i)*ones(1,size(fv{i}.vertices,1)))';
end

%% Render
% The model is rendered with a PATCH graphics object. We also add some dynamic
% lighting, and adjust the material properties to change the specular
% highlighting.
figure('units','pixels','pos',[-1000 200 900 900]);
hold on;
title('KUKA LWR iiwa R820');
axis equal;
axis([-1 1 -1 1 -0.5 1]);
xlabel('x'); ylabel('y'); zlabel('z');

% draw base link
patch(fv_base,'FaceColor',       [1 1 1], ...
             'EdgeColor',       'none',        ...
             'FaceLighting',    'gouraud',     ...
             'AmbientStrength', 0.15);

% draw 7 links
for i = 1:7
    render_part{i} = patch(fv{i},'FaceColor',  [246 120 40]/255, ...
             'EdgeColor',       'none',        ...
             'FaceLighting',    'gouraud',     ...
             'AmbientStrength', 0.15);
end

% draw end-effector
end_effector_M = eye(4);
end_effector_M(3,4) = 0.12;
end_effector_T = T(:,:,7) * end_effector_M;
end_effector = draw_SE3(end_effector_T);

% plot_inertiatensor(T, robot.G, 0.5, rand(7,3));


% Add a camera light, and tone down the specular highlighting
camlight('headlight');
material('dull');

% Fix the axes scaling, and set a nice view angle
view([-135 35]);
getframe;

%% Animation

% while(1)
%     q(joint) = q(joint) + 0.2;
%     
%     for i = 1:n
%         T(:,:,i) = solveForwardKinematics(q(1:i), robot.A(:,1:i), robot.M(:,:,1:i));
%         fv{i}.vertices = (T(1:3,1:3,i)*fv_zero{i}.vertices' + T(1:3,4,i)*ones(1,size(fv_zero{i}.vertices,1)))';
%     end
%     
%     for i = 1:n
%         set(render_part{i}, 'Vertices', fv{i}.vertices, 'FaceColor',  [q(joint)-floor(q(joint)) 0 0]);
%     end
%     
%     end_effector_T = T(:,:,7) * end_effector_M;
%     draw_SE3(end_effector_T, end_effector);
%     
%     getframe;
% end

%%
num_sample = 200;
sample_time = linspace(0,trajectory.horizon,num_sample);
q_opti = makeFourier(p_optimal, trajectory.base_frequency, sample_time);

while(1)
    tic
    for time = 1:num_sample
        for i = 1:n
            T(:,:,i) = solveForwardKinematics(q_opti(1:i,time), robot.A(:,1:i), robot.M(:,:,1:i));
            fv{i}.vertices = (T(1:3,1:3,i)*fv_zero{i}.vertices' + T(1:3,4,i)*ones(1,size(fv_zero{i}.vertices,1)))';
        end

        for i = 1:n
            set(render_part{i}, 'Vertices', fv{i}.vertices);
        end

        end_effector_T = T(:,:,7) * end_effector_M;
        draw_SE3(end_effector_T, end_effector);

        getframe;
    end
    toc
end