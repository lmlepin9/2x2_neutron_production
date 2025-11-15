import numpy as np
import matplotlib.pyplot as plt
import h5py 
import sys 
import os 

def generate_random_time(time_window):
    '''
    This function generates a uniform random time 
    within a designated time window.
    '''
    random_time = np.random.rand()*(time_window[1] - time_window[0])
    random_time += time_window[0]
    return random_time 



def force_capture_time(input_file, output_file, random=False, time_window=(0.,9)):

    '''
    This function iterates over the captures events in the input file 
    and removes all the trajectories/segments occuring before the neutron capture.
    In addition it centers all the activity around a given offset time.

    input_file: input .hdf5 file with captures inside the 2x2 volume
    output_file: name of your output .hdf5 file 
    random: Decide between fixed offset or offset from uniform random time
    time_window: time window in us for random time  
    
    '''

    with h5py.File(input_file, "r") as h5_in, h5py.File(output_file, "w") as h5_out:
        # Copy dtypes from original file
        vertices_dtype = h5_in["vertices"].dtype
        trajectories_dtype = h5_in["trajectories"].dtype
        segments_dtype = h5_in["segments"].dtype

        # Create empty resizable datasets in output
        v_out = h5_out.create_dataset("vertices", shape=(0,), maxshape=(None,), dtype=vertices_dtype)
        t_out = h5_out.create_dataset("trajectories", shape=(0,), maxshape=(None,), dtype=trajectories_dtype)
        s_out = h5_out.create_dataset("segments", shape=(0,), maxshape=(None,), dtype=segments_dtype)

        # Prepare buffers
        v_buf, t_buf, s_buf = [], [], []

        vertices = h5_in["vertices"]
        trajectories = h5_in["trajectories"]
        segments = h5_in["segments"]

        ev_id_mod = 1
        for ev_id in np.unique(vertices['event_id']):
            # Select data for this event
            event_time = (1e6)*1.2*ev_id_mod
            ev = vertices[vertices['event_id'] == ev_id].copy()
            ev_traj = trajectories[trajectories["event_id"] == ev_id].copy()
            ev_seg = segments[segments["event_id"] == ev_id].copy()

            capture_time = ev_traj[ev_traj['pdg_id']==1000180410]['t_start']
            if(len(capture_time)==0): 
                continue


            # Search for capture gammas

            capture_gammas = ev_traj[(ev_traj['pdg_id']==22) & (ev_traj['start_process']==4) & (ev_traj['start_subprocess']==131)]
            E_capture_gammas = np.sum(capture_gammas['E_start'])
            # Get rid of uncompleted cascade events 
            if(E_capture_gammas < 6):
                continue

            # Filter by capture_time
            ev_traj = ev_traj[ev_traj["t_start"] >= capture_time]
            ev_seg = ev_seg[ev_seg["t0_start"] >= capture_time]

            if len(ev_traj) == 0 and len(ev_seg) == 0:
                continue  # skip events with nothing left

            # Shift times
            capture_time = capture_time - ev["t_event"]


            if(random):
                offset_time = generate_random_time(time_window)
            else:
                offset_time = 5 # us 

            for field in ["t_start", "t_end"]:
                if field in ev_traj.dtype.names:
                    ev_traj[field] = (ev_traj[field] - capture_time + offset_time) - ev["t_event"] + event_time

            for field in ["t0_start", "t0_end", "t0", "t"]:
                if field in ev_seg.dtype.names:
                    ev_seg[field] = (ev_seg[field] - capture_time + offset_time) - ev["t_event"] + event_time 

            # --- overwrite event_id with ev_id_mod ---
            ev["event_id"] = ev_id_mod
            ev['t_event'] = event_time
            ev_traj["event_id"] = ev_id_mod
            ev_seg["event_id"] = ev_id_mod



            # Collect
            v_buf.extend(np.array(ev, dtype=vertices_dtype))  
            t_buf.extend(np.array(ev_traj, dtype=trajectories_dtype))
            s_buf.extend(np.array(ev_seg, dtype=segments_dtype))

            if v_buf:
                v_arr = np.array(v_buf, dtype=vertices_dtype)
                v_out.resize((len(v_arr),))
                v_out[:] = v_arr

            if t_buf:
                t_arr = np.array(t_buf, dtype=trajectories_dtype)
                t_out.resize((len(t_arr),))
                t_out[:] = t_arr

            if s_buf:
                s_arr = np.array(s_buf, dtype=segments_dtype)
                s_out.resize((len(s_arr),))
                s_out[:] = s_arr

            # increment new event counter
            ev_id_mod += 1
        print(f"Number of entries in modified file {len(v_out['event_id'])}")
    print("Filtered file written to", output_file)



if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python force_capture_time.py <input_file> <output_file> [offset_time]")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    if len(sys.argv) >=4:
        offset_time = int(sys.argv[3])
    else:
        offset_time = 5 # default value

    force_capture_time(input_file,output_file, offset_time)




