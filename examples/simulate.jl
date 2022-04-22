using Printf
using KiteModels, KitePodModels, KiteUtils

# change this to KPS3 or KPS4
const Model = KPS4

if ! @isdefined kcu;  const kcu = KCU(se());   end
if ! @isdefined kps4; const kps4 = Model(kcu); end

# the following values can be changed to match your interest
dt = 0.05
TIME = 30.0
STEPS = round(TIME/dt)
PLOT = false
FRONT_VIEW = false
ZOOM = true
PRINT = false
STATISTIC = false
# end of user parameter section #

if PLOT
    using Plots
    include("plot2d.jl")
end

function simulate(integrator, steps, plot=false)
    start = integrator.p.iter
    for i in 1:steps
        if PRINT
            lift, drag = KiteModels.lift_drag(kps4)
            @printf "%.2f: " round(integrator.t, digits=2)
            println("lift, drag  [N]: $(round(lift, digits=2)), $(round(drag, digits=2))")
        end

        KiteModels.next_step!(kps4, integrator, dt=dt)
        
        if plot
            reltime = i*dt
            if mod(i, 5) == 0
                p = plot2d(kps4.pos, reltime; zoom=ZOOM, front=FRONT_VIEW, segments=se().segments)
                display(p)                
            end
        end
    end
    (integrator.p.iter - start) / steps
end

integrator = KiteModels.init_sim!(kps4, stiffness_factor=0.04, prn=STATISTIC)

if PLOT
    av_steps = simulate(integrator, STEPS, true)
else
    println("\nStarting simulation...")
    simulate(integrator, STEPS*0.25)
    runtime = @elapsed av_steps = simulate(integrator, STEPS*0.75)
    println("\nTotal simulation time: $(round(runtime, digits=3)) s")
    speed = (STEPS*0.75) / runtime * dt
    println("Simulation speed: $(round(speed, digits=2)) times realtime.")
end
lift, drag = KiteModels.lift_drag(kps4)
println("lift, drag  [N]: $(round(lift, digits=2)), $(round(drag, digits=2))")
println("Average number of callbacks per time step: $av_steps")
