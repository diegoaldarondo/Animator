# Animator

## WIP Updates on branch: `dependency_fixes`
Issue: cannot run Label3D on newer systems. E.g. Apple Silicon Macs. 

The issue is loading individual frames from a video file with mmread & FFGrab.
Unfortunately, mmread has not been updated in ~15 years (as of 2024), and the code is not compatible with newer versions of Matlab and C++. This also depends on AVbin & libav which have not been updated in 10+ years and no longer has a working website.

This branch attempts to fix some of these issues to the point that FFGrab will compile to MEX files (e.g. FFGrab.mexmaci, etc.).

The following steps done to compile FFGrab on mac:
1. install FFPEG with homebrew
2. install XCode
3. install/enable Rosetta2
4. install `AVBin` from Github: [here](https://github.com/AVbin/AVbin)
5.  replace this file in AVbin: `AVbin/macosx-x86-64.Makefile` with the following updated file:

```Makefile
LIBNAME=$(OUTDIR)/libavbin.$(AVBIN_VERSION).dylib

CFLAGS += -O3 -arch x86_64
CFLAGS += -target x86_64-apple-darwin20.3.0

LDFLAGS += -dylib \
           -arch x86_64 \
           -install_name @rpath/libavbin.dylib \
           -macosx_version_min 10.6 \
           -framework CoreFoundation \
           -framework CoreVideo \
           -framework VideoDecodeAcceleration \
           -F/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/


STATIC_LIBS = $(BACKEND_DIR)/libavformat/libavformat.a \
              $(BACKEND_DIR)/libavcodec/libavcodec.a \
              $(BACKEND_DIR)/libavutil/libavutil.a \
              $(BACKEND_DIR)/libswscale/libswscale.a


LIBS = -lSystem \
       -lz \
       -lbz2


$(LIBNAME) : $(OBJNAME) $(OUTDIR)
	$(LD) $(LDFLAGS) -o $@ $< $(STATIC_LIBS) $(LIBS) -L /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX14.2.sdk/usr/lib
```

6. Run the following command from a Rosetta 2 terminal in the `AVLib` directory: `./build.sh macosx-x86-64 -L /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX14.2.sdk/usr/lib`

7. Copy the compiled dynamic libray from `libavbin.11.dylib` to `/usr/local/lib`
8. Create a symlink from `libavbin.11.dylib` to `libavbin.dylib`: `ln -s libavbin.11.dylin libavbin.dylib`
9. Copy the header file from the AVLib repo: `include/avbin.h` to `/usr/local/include`
10. Open matlab in the label3d directory, and run the following ocmmand in the matlab command window: `mex -compatibleArrayDims FFGrab.cpp -I/opt/homebrew/Cellar/ffmpeg/6.1.1_2/include -L/usr/local/lib -lavbin -I/usr/local/include`

11. WIP - still unable to run readFrame from label3D because of linking issues, but everything should compile at this point. Instead, I'm working on alternative libraries which are more up-to-date and don't require as much configuration

# Package Introduction
`Animator` is a general purpose toolbox for interactive data animation in MATLAB.
It can be used to animate videos and charts with an intuitive user interface.
You can link `Animators` together to build powerful custom interactive visualizations. 
You can also easily write videos with `Animators`, allowing you to share your visualizations with others. 

## Installation
```
git clone https://github.com/diegoaldarondo/Animator.git
```

## Animated Charts
You can use `Animators` to interactively visualize many types of data. This is done through specialized `Animator` subclasses: 
* VideoAnimator
* ScatterAnimator
* Scatter3Animator
* Keypoint2DAnimator
* DraggableKeypoint2DAnimator
* Keypoint3DAnimator
* TraceAnimator
* StackedTraceAnimator
* QuiverAnimator
* RasterAnimator
* HeatMapAnimator

## Examples
Look at `AnimatorExamples.m` for a guide on how to use different `Animator` classes. 
