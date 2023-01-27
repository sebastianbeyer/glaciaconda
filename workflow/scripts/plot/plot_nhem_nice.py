import matplotlib.pyplot as plt
import hyoga

import argparse

parser = argparse.ArgumentParser(description='plot ice data.')
parser.add_argument('inputfile')
parser.add_argument('outputfile')
parser.add_argument('--timestep', default=0)

args = parser.parse_args()


# fig, axes = plt.subplots(figsize=[11,8])#ncols=1) #Creating the basis for the plot
fig, axes = plt.subplots()#ncols=1) #Creating the basis for the plot

gdf = hyoga.open.paleoglaciers('bat19').to_crs("+ellps=WGS84 +datum=WGS84 +lat_ts=71.0 +proj=stere +x_0=0.0 +units=m +lon_0=-44.0 +lat_0=90.0")

# plot example data
#with hyoga.open.dataset('./gi_cold_mprange_clemdyn_-40000_-35000.nc') as ds:
# with hyoga.open.dataset('./ex_gi_cold_mprange_clemdyn_-35000_-30000.nc') as dsall:
with hyoga.open.dataset(args.inputfile) as dsall:
    cond = (dsall.x>-4700000) & (dsall.x<1550000) & (dsall.y>-49250000) & (dsall.y<960000)
    cond =(dsall.x<3.5e6) & (dsall.y<2.5e6)
    dssmall = dsall.where(cond,drop=True)
    # dssmall = dsall

    ds = dssmall.isel(age=0)
    ds.hyoga.plot.bedrock_altitude(center=False, ax=axes)
    # margin = ds.hyoga.plot.ice_margin(facecolor='white',zorder=-10)
    margin = ds.hyoga.plot.ice_margin(facecolor='white',)
    ds.hyoga.plot.surface_velocity(vmin=1e1, vmax=1e3, ax=axes)
    cont = ds.hyoga.plot.surface_altitude_contours(ax=axes)
    ds.hyoga.plot.surface_velocity_streamplot(
        cmap='Blues', vmin=1e1, vmax=1e3, density=(7, 7))


    # paleo glacier extent
    gdf.plot(ax=axes, alpha=0.2, zorder=0)


    # ds.hyoga.plot.scale_bar()
    axes.text(0.95, 0.02, '{} years ago'.format(ds.age.data),
        verticalalignment='bottom', horizontalalignment='right',
        transform=axes.transAxes,
        color='black', fontsize=11)

    axes.set_xlim(-6.24e6, 3.5e6)
    axes.set_ylim(-6.24e6, 2.5e6)

    plt.savefig(args.outputfile, dpi=200)

    # plt.show()



    # ds.hyoga.plot.ice_margin(facecolor='tab:blue')
    # ds.hyoga.plot.surface_hillshade()
    # ds.hyoga.plot.surface_velocity_streamplot(
    #     cmap='Blues', vmin=1e0, vmax=1e3, density=(15, 15))
    # ds.hyoga.plot.natural_earth()

# set title
# plt.title('A first plot with hyoga')
# plt.show()
