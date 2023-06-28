//
//  ViewController.swift
//  ARDemo
//
//  Created by Artem Vaniukov on 27.06.2023.
//

import UIKit
import RealityKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(clearButtonDidTap), for: .touchUpInside)
        button.setTitle("Clear all", for: .normal)
        return button
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = .init(width: 80, height: 80)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceHorizontal = true
        collectionView.allowsSelection = true
        return collectionView
    }()
    
    private var selectedEntity: Entity?
    private var initialEntityPosition: SIMD3<Float>?
    private var initialEntityScale: SIMD3<Float>?
    private var initialEntityRotation: simd_quatf?
    
    private let furnitureModels = Furniture.allCases
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupGestures()
    }
    
    private func getIntersectedEntity(at location: CGPoint) -> Entity? {
        arView.hitTest(location).first?.entity
    }
    
    private func prepareObject(_ object: Furniture) {
        let model = object.model
        let goal = object.goal
        
        model.name = object.name
        
        arView.addCoaching(for: goal)
        arView.scene.anchors.append(model as! HasAnchoring)
        
        selectedEntity = model
    }
}

// MARK: - Actions

private extension ViewController {
    @objc func clearButtonDidTap() {
        arView.scene.anchors.removeAll()
    }
    
    @objc func didTapCell(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: collectionView)
        
        if let indexPath = collectionView.indexPathForItem(at: location) {
            let furniture = furnitureModels[indexPath.item]
            prepareObject(furniture)
        }
    }
    
    @objc func didSelectObject(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: arView)
        
        if let selectedEntity = getIntersectedEntity(at: location) {
            self.selectedEntity = selectedEntity
        } else {
            selectedEntity = nil
        }
    }
    
    @objc func didMoveObject(recognizer: UIPanGestureRecognizer) {
        guard let entity = selectedEntity else { return }
        
        switch recognizer.state {
        case .began:
            initialEntityPosition = entity.transform.translation
            
        case .changed:
            guard let initialPosition = initialEntityPosition else { return }
            
            let translation = recognizer.translation(in: arView)
            let dampingFactor: Float = 0.001
            
            var transform = entity.transform
            let deltaX = Float(translation.x) * dampingFactor
            let deltaY = Float(translation.y) * dampingFactor
            
            transform.translation = initialPosition + SIMD3(deltaX, 0, deltaY)
            entity.transform = transform
            
        case .ended:
            initialEntityPosition = nil
            
        default:
            break
        }
    }
    
    @objc func didScaleObject(recognizer: UIPinchGestureRecognizer) {
        guard let entity = selectedEntity else { return }
        
        switch recognizer.state {
        case .began:
            initialEntityScale = entity.transform.scale
            
        case .changed:
            guard let initialScale = initialEntityScale else { return }
            
            let scale = Float(recognizer.scale)
            let dampingFactor: Float = 0.1
            
            var transform = entity.transform
            let scaledScale = initialScale * scale
            let dampedScale = mix(transform.scale, scaledScale, t: dampingFactor)
            
            transform.scale = dampedScale
            entity.transform = transform
            
        case .ended:
            initialEntityScale = nil
            
        default:
            break
        }
    }
    
    @objc func didRotateObject(recognizer: UIRotationGestureRecognizer) {
        guard let entity = selectedEntity else { return }
        
        switch recognizer.state {
        case .began:
            initialEntityRotation = entity.transform.rotation
            
        case .changed:
            guard let initialRotation = initialEntityRotation else { return }
            
            let rotation = -Float(recognizer.rotation)
            let dampingFactor: Float = 0.2
            
            var transform = entity.transform
            let rotatedRotation = initialRotation * simd_quatf(angle: rotation, axis: SIMD3(0, 1, 0))
            let dampedRotation = simd_slerp(transform.rotation, rotatedRotation, dampingFactor)
            
            transform.rotation = dampedRotation
            entity.transform = transform
            
        case .ended:
            initialEntityRotation = nil
            
        default:
            break
        }
    }
}

// MARK: - UICollectionViewDelegate

extension ViewController: UICollectionViewDelegate {}
    
// MARK: - UICollectionViewDataSource

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        furnitureModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FurnitureCell
        let model = furnitureModels[indexPath.item]
        cell.label.text = model.name
        cell.contentView.backgroundColor = .blue.withAlphaComponent(0.3)
        return cell
    }
}

// MARK: - Gestures

private extension ViewController {
    func setupGestures() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSelectObject(recognizer:)))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didMoveObject(recognizer:)))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(didScaleObject(recognizer:)))
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(didRotateObject(recognizer:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
        arView.addGestureRecognizer(panGestureRecognizer)
        arView.addGestureRecognizer(pinchGestureRecognizer)
        arView.addGestureRecognizer(rotationGestureRecognizer)
    }
}

// MARK: - Layout

private extension ViewController {
    func setupLayout() {
        setupClearButton()
        setupCollectionView()
    }
    
    func setupClearButton() {
        view.addSubview(clearButton)
        
        NSLayoutConstraint.activate([
            clearButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            clearButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            clearButton.widthAnchor.constraint(equalToConstant: 80),
            clearButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func setupCollectionView() {
        collectionView.isUserInteractionEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(FurnitureCell.self, forCellWithReuseIdentifier: "cell")
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapCell(recognizer:)))
        collectionView.addGestureRecognizer(tapGestureRecognizer)
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            collectionView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
}

// MARK: - ARView+Extension

extension ARView: ARCoachingOverlayViewDelegate {
    func addCoaching(for goal: ARCoachingOverlayView.Goal) {
        let coachingOverlayView = ARCoachingOverlayView()
        coachingOverlayView.delegate = self
        coachingOverlayView.session = session
        coachingOverlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlayView.center = center
        coachingOverlayView.goal = goal
        addSubview(coachingOverlayView)
    }
    
    func removeCoaching() {
        for view in subviews where view is ARCoachingOverlayView {
            view.removeFromSuperview()
        }
    }
    
    public func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        coachingOverlayView.removeFromSuperview()
    }
}
