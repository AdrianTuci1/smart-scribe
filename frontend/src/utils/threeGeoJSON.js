import * as THREE from "three";
import { LineMaterial } from "three/examples/jsm/lines/LineMaterial.js";
import { LineGeometry } from "three/examples/jsm/lines/LineGeometry.js";
import { Line2 } from "three/examples/jsm/lines/Line2.js";

/* Draw GeoJSON
Iterates through the latitude and longitude values, converts the values to XYZ coordinates,
and draws the geoJSON geometries.
*/

export function drawThreeGeo({ json, radius, materialOptions }) {
    const container = new THREE.Object3D();

    // Pivot to fix orientation: rotate -90 degrees around X axis
    container.rotation.x = -Math.PI * 0.5;

    const x_values = [];
    const y_values = [];
    const z_values = [];
    const json_geom = createGeometryArray(json);

    let coordinate_array = [];
    for (let geom_num = 0; geom_num < json_geom.length; geom_num++) {
        const geom = json_geom[geom_num];
        if (geom.type === 'Point') {
            convertToSphereCoords(geom.coordinates, radius);
            drawParticle(x_values[0], y_values[0], z_values[0], materialOptions);
        } else if (geom.type === 'MultiPoint') {
            for (let point_num = 0; point_num < geom.coordinates.length; point_num++) {
                convertToSphereCoords(geom.coordinates[point_num], radius);
                drawParticle(x_values[0], y_values[0], z_values[0], materialOptions);
            }
        } else if (geom.type === 'LineString') {
            coordinate_array = createCoordinateArray(geom.coordinates);
            for (let point_num = 0; point_num < coordinate_array.length; point_num++) {
                convertToSphereCoords(coordinate_array[point_num], radius);
            }
            drawLine(x_values, y_values, z_values, materialOptions);
        } else if (geom.type === 'Polygon') {
            for (let segment_num = 0; segment_num < geom.coordinates.length; segment_num++) {
                coordinate_array = createCoordinateArray(geom.coordinates[segment_num]);
                for (let point_num = 0; point_num < coordinate_array.length; point_num++) {
                    convertToSphereCoords(coordinate_array[point_num], radius);
                }
                drawLine(x_values, y_values, z_values, materialOptions);
            }
        } else if (geom.type === 'MultiLineString') {
            for (let segment_num = 0; segment_num < geom.coordinates.length; segment_num++) {
                coordinate_array = createCoordinateArray(geom.coordinates[segment_num]);
                for (let point_num = 0; point_num < coordinate_array.length; point_num++) {
                    convertToSphereCoords(coordinate_array[point_num], radius);
                }
                drawLine(x_values, y_values, z_values, materialOptions);
            }
        } else if (geom.type === 'MultiPolygon') {
            for (let polygon_num = 0; polygon_num < geom.coordinates.length; polygon_num++) {
                for (let segment_num = 0; segment_num < geom.coordinates[polygon_num].length; segment_num++) {
                    coordinate_array = createCoordinateArray(geom.coordinates[polygon_num][segment_num]);
                    for (let point_num = 0; point_num < coordinate_array.length; point_num++) {
                        convertToSphereCoords(coordinate_array[point_num], radius);
                    }
                    drawLine(x_values, y_values, z_values, materialOptions);
                }
            }
        }
    }

    function createGeometryArray(json) {
        let geometry_array = [];
        if (json.type === 'Feature') {
            geometry_array.push(json.geometry);
        } else if (json.type === 'FeatureCollection') {
            for (let feature_num = 0; feature_num < json.features.length; feature_num++) {
                geometry_array.push(json.features[feature_num].geometry);
            }
        } else if (json.type === 'GeometryCollection') {
            for (let geom_num = 0; geom_num < json.geometries.length; geom_num++) {
                geometry_array.push(json.geometries[geom_num]);
            }
        }
        return geometry_array;
    }

    function createCoordinateArray(feature) {
        const temp_array = [];
        let interpolation_array = [];
        for (let point_num = 0; point_num < feature.length; point_num++) {
            const point1 = feature[point_num];
            const point2 = feature[point_num - 1];
            if (point_num > 0) {
                if (needsInterpolation(point2, point1)) {
                    interpolation_array = [point2, point1];
                    interpolation_array = interpolatePoints(interpolation_array);
                    for (let inter_point_num = 0; inter_point_num < interpolation_array.length; inter_point_num++) {
                        temp_array.push(interpolation_array[inter_point_num]);
                    }
                } else {
                    temp_array.push(point1);
                }
            } else {
                temp_array.push(point1);
            }
        }
        return temp_array;
    }

    function needsInterpolation(point2, point1) {
        const lon1 = point1[0], lat1 = point1[1];
        const lon2 = point2[0], lat2 = point2[1];
        return Math.abs(lon1 - lon2) > 5 || Math.abs(lat1 - lat2) > 5;
    }

    function interpolatePoints(interpolation_array) {
        let temp_array = [];
        for (let point_num = 0; point_num < interpolation_array.length - 1; point_num++) {
            const point1 = interpolation_array[point_num];
            const point2 = interpolation_array[point_num + 1];
            if (needsInterpolation(point2, point1)) {
                temp_array.push(point1);
                temp_array.push([(point1[0] + point2[0]) / 2, (point1[1] + point2[1]) / 2]);
            } else {
                temp_array.push(point1);
            }
        }
        temp_array.push(interpolation_array[interpolation_array.length - 1]);
        if (temp_array.length > interpolation_array.length) {
            temp_array = interpolatePoints(temp_array);
        }
        return temp_array;
    }

    function convertToSphereCoords(coordinates_array, sphere_radius) {
        const lon = coordinates_array[0], lat = coordinates_array[1];
        const radLat = lat * Math.PI / 180;
        const radLon = lon * Math.PI / 180;
        x_values.push(Math.cos(radLat) * Math.cos(radLon) * sphere_radius);
        y_values.push(Math.cos(radLat) * Math.sin(radLon) * sphere_radius);
        z_values.push(Math.sin(radLat) * sphere_radius);
    }

    function drawParticle(x, y, z, options) {
        const geo = new THREE.BufferGeometry();
        geo.setAttribute("position", new THREE.Float32BufferAttribute([x, y, z], 3));
        const particle = new THREE.Points(geo, new THREE.PointsMaterial(options));
        container.add(particle);
        clearArrays();
    }

    function drawLine(x_vals, y_vals, z_vals, options) {
        const lineGeo = new LineGeometry();
        const verts = [];
        for (let i = 0; i < x_vals.length; i++) {
            verts.push(x_vals[i], y_vals[i], z_vals[i]);
        }
        lineGeo.setPositions(verts);

        // Custom logic from source for some variety in colors if not provided
        const color = options.color || (new THREE.Color().setHSL(0.6, 0.5, 0.5));

        const lineMaterial = new LineMaterial({
            color: color,
            linewidth: options.linewidth || 1,
            transparent: true,
            opacity: options.opacity || 1
        });

        const line = new Line2(lineGeo, lineMaterial);
        line.computeLineDistances();
        container.add(line);
        clearArrays();
    }

    function clearArrays() {
        x_values.length = 0;
        y_values.length = 0;
        z_values.length = 0;
    }

    return container;
}
