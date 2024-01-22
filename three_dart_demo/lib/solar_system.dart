import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three3d/math/math.dart';
import 'package:three_dart/three_dart.dart' as three;
import 'package:three_dart_jsm/three_dart_jsm.dart' as three_jsm;

class SolarSystem extends StatefulWidget {
  const SolarSystem({super.key});

  @override
  State<SolarSystem> createState() => _SolarSystemState();
}

class _SolarSystemState extends State<SolarSystem> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  late three.Camera camera;
  late three.Scene scene;
  late three.Mesh mesh;
  late three.Group group;
  late List<three.Material> materials;

  late three.Mesh sun;
  late three.Mesh mercury;
  late three.Mesh venus;
  late three.Mesh earth;
  late three.Mesh mars;
  late three.Mesh jupiter;
  late three.Mesh saturn;
  late three.Mesh uranus;
  late three.Mesh neptune;

  Size? screenSize;
  double dpr = 1.0;

  late double width;
  late double height;

  late three.WebGLRenderTarget renderTarget;
  dynamic sourceTexture;

  final GlobalKey<three_jsm.DomLikeListenableState> _globalKey =
      GlobalKey<three_jsm.DomLikeListenableState>();

  late three_jsm.OrbitControls controls;
  bool disposed = false;
  bool verbose = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Builder(builder: (BuildContext context) {
          intiSize(context);
          return _buiild(context);
        }),
        floatingActionButton: FloatingActionButton(
          child: const Text("render"),
          onPressed: () {
            render();
          },
        ));
  }

//method to get screeensize and pixel ratio of device
  intiSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }

  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    await three3dRender.initialize(options: options);

    //no idea about this one
    setState(() {});

    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  initScene() {
    initRenderer();
    initPage();
  }

  initRenderer() {
    Map<String, dynamic> options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };
    renderer = three.WebGLRenderer(options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = false;

    if (!kIsWeb) {
      var pars = three.WebGLRenderTargetOptions({
        "minFilter": three.LinearFilter,
        "magFilter": three.LinearFilter,
        "format": three.RGBAFormat
      });
      renderTarget = three.WebGLRenderTarget(
          (width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  initPage() {
    scene = three.Scene();
    scene.background = three.Color(0x000000);

    camera = three.PerspectiveCamera(45, width / height, 0.1, 1000);
    camera.position.z = 300;

    controls = three_jsm.OrbitControls(camera, _globalKey);
    controls.enableDamping = true;
    controls.dampingFactor = 0.25;

    sun = createSphere(12, 0xFFD307); // Sun
    mercury = createSphere(1, 0xBFBFBF); // Mercury
    venus = createSphere(2, 0xE5B76E); // Venus
    earth = createSphere(2, 0x1E90FF); // Earth
    mars = createSphere(1.5, 0xFF4500); // Mars
    jupiter = createSphere(9, 0xD2B48C); // Jupiter
    saturn = createSphere(8, 0xDAA520); // Saturn
    uranus = createSphere(4, 0xADD8E6); // Uranus
    neptune = createSphere(4, 0x00008B); // Neptune

    // Set initial positions
    sun.position.set(0, 0, 0);
    mercury.position.set(25, 0, 0);
    venus.position.set(35, 0, 0);
    earth.position.set(50, 0, 0);
    mars.position.set(70, 0, 0);
    jupiter.position.set(100, 0, 0);
    saturn.position.set(130, 0, 0);
    uranus.position.set(160, 0, 0);
    neptune.position.set(190, 0, 0);

    // Add objects to the scene
    scene.add(sun);
    scene.add(mercury);
    scene.add(venus);
    scene.add(earth);
    scene.add(mars);
    scene.add(jupiter);
    scene.add(saturn);
    scene.add(uranus);
    scene.add(neptune);

    // Lights
    var ambientLight = three.AmbientLight(0x404040);
    scene.add(ambientLight);

    var pointLight = three.PointLight(0xffffff, 0.5);
    pointLight.position.set(0, 0, 0);
    scene.add(pointLight);
    var sunLight = three.PointLight(0xffffff, 0.7);
    sunLight.position.set(0, 0, 100);
    scene.add(sunLight);

    // Add starfield
    addStarfield();

    animate();
  }

  void addStarfield() {
    final random = Random();

    for (var i = 0; i < 800; i++) {
      var x = ((random.nextDouble() - 0.5) * 500);
      var y = ((random.nextDouble() - 0.5) * 500);
      var z = ((random.nextDouble() - 0.5) * 500);

      var star = createSphere(0.4, 0xFFFFFF);
      star.position.set(x, y, z);
      scene.add(star);
    }
  }

  createSphere(double radius, int color) {
    var geometry = three.SphereGeometry(radius, 50, 50);
    var material = three.MeshPhongMaterial({"color": color});
    return three.Mesh(geometry, material);
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    // Rotate the entire solar system
    sun.rotation.y += 0.001;

// Move planets in their orbital paths with reduced speeds
    mercury.position.x =
        25 * Math.cos(0.005 * DateTime.now().millisecondsSinceEpoch);
    mercury.position.z =
        25 * Math.sin(0.005 * DateTime.now().millisecondsSinceEpoch);

    venus.position.x =
        35 * Math.cos(0.003 * DateTime.now().millisecondsSinceEpoch);
    venus.position.z =
        35 * Math.sin(0.003 * DateTime.now().millisecondsSinceEpoch);

    earth.position.x =
        50 * Math.cos(0.002 * DateTime.now().millisecondsSinceEpoch);
    earth.position.z =
        50 * Math.sin(0.002 * DateTime.now().millisecondsSinceEpoch);

    mars.position.x =
        70 * Math.cos(0.001 * DateTime.now().millisecondsSinceEpoch);
    mars.position.z =
        70 * Math.sin(0.001 * DateTime.now().millisecondsSinceEpoch);

    jupiter.position.x =
        100 * Math.cos(0.0005 * DateTime.now().millisecondsSinceEpoch);
    jupiter.position.z =
        100 * Math.sin(0.0005 * DateTime.now().millisecondsSinceEpoch);

    saturn.position.x =
        130 * Math.cos(0.0004 * DateTime.now().millisecondsSinceEpoch);
    saturn.position.z =
        130 * Math.sin(0.0004 * DateTime.now().millisecondsSinceEpoch);

    uranus.position.x =
        160 * Math.cos(0.0003 * DateTime.now().millisecondsSinceEpoch);
    uranus.position.z =
        160 * Math.sin(0.0003 * DateTime.now().millisecondsSinceEpoch);

    neptune.position.x =
        190 * Math.cos(0.0002 * DateTime.now().millisecondsSinceEpoch);
    neptune.position.z =
        190 * Math.sin(0.0002 * DateTime.now().millisecondsSinceEpoch);

    render();

    Future.delayed(const Duration(milliseconds: 40), () {
      animate();
    });
  }

  render() {
    final gl = three3dRender.gl;

    renderer!.render(scene, camera);

    gl.flush();

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  Widget _buiild(BuildContext context) {
    return three_jsm.DomLikeListenable(
        key: _globalKey,
        builder: (BuildContext context) {
          return Container(
              width: width,
              height: height,
              color: Colors.black,
              child: Builder(builder: (BuildContext context) {
                if (kIsWeb) {
                  return three3dRender.isInitialized
                      ? HtmlElementView(
                          viewType: three3dRender.textureId!.toString())
                      : Container();
                } else {
                  return three3dRender.isInitialized
                      ? Texture(textureId: three3dRender.textureId!)
                      : Container();
                }
              }));
        });
  }

  @override
  void dispose() {
    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }
}
