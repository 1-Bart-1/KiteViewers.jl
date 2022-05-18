# using KiteUtils
# se().segments=15

using Pkg
if ! ("KitePodModels" ∈ keys(Pkg.project().dependencies))
    using TestEnv; TestEnv.activate()
end

using KiteViewers, KiteModels, KitePodModels, Rotations

const Model = KPS4

if ! @isdefined kcu;  const kcu = KCU(se());   end
if ! @isdefined kps4; const kps4 = Model(kcu); end

# the following values can be changed to match your interest
dt = 0.05
TIME = 50
TIME_LAPSE_RATIO = 5
STEPS = Int64(round(TIME/dt))
STATISTIC = false
SHOW_KITE = true
PLOT_PERFORMANCE = false
# end of user parameter section #

if Model==KPS3 SHOW_KITE = true end

if ! @isdefined time_vec; const time_vec = zeros(div(STEPS, TIME_LAPSE_RATIO)); end
if ! @isdefined viewer; const viewer = Viewer3D(SHOW_KITE); end

# ffmpeg -r:v 20 -i "video%06d.png" -codec:v libx264 -preset veryslow -pix_fmt yuv420p -crf 10 -an "video.mp4"

include("timers.jl")

function simulate(integrator, steps)
    start = integrator.p.iter
    start_time = time()
    time_ = 0.0
    KiteViewers.clear_viewer(viewer)
    for i in 1:steps
        iter = kps4.iter
        if i == 300
            set_depower_steering(kps4.kcu, 0.30, 0.0)
        elseif i == 640
            set_depower_steering(kps4.kcu, 0.35, 0.0)    
        end
        KiteModels.next_step!(kps4, integrator, dt=dt)     
        if mod(i, TIME_LAPSE_RATIO) == 0 || i == steps
            update_system(viewer, SysState(kps4); scale = 0.08, kite_scale=3.0)
            if start_time+dt > time() + 0.002
                wait_until(start_time+dt) 
            else
                sleep(0.001)
            end
            start_time = time()
            time_vec[div(i, TIME_LAPSE_RATIO)]=time_/(TIME_LAPSE_RATIO*dt)*100.0
            time_ = 0.0
        end
        time_ += (kps4.iter - iter)*1.28e-6
        if viewer.stop break end
    end
    (integrator.p.iter - start) / steps
end

function play()
    integrator = KiteModels.init_sim!(kps4, stiffness_factor=0.04, prn=STATISTIC)
    simulate(integrator, STEPS)
end

on(viewer.btn_PLAY.clicks) do c
    @async play()
end
on(viewer.btn_STOP.clicks) do c
   viewer.stop = true
end

play()
nothing