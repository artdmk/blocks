//
//  GameViewController.swift
//  blocks
//
//  Created by Artem Demchenko on 20.02.16.
//  Copyright (c) 2016 artdmk. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController, BlocksDelegate, UIGestureRecognizerDelegate {

    var scene: GameScene!
    var blocks:Blocks!
    
    var panPointReference:CGPoint?
    
    @IBOutlet weak var scoreLabel: UILabel!
    
    @IBOutlet weak var levelLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //configure the view
        let skView = view as! SKView
        skView.multipleTouchEnabled = false
        
        //create and configure the scene    
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        
        scene.tick = didTick
        blocks = Blocks()
        blocks.delegate = self
        blocks.beginGame()
        
        //present the scene
        skView.presentScene(scene)
    
//        scene.addPreviewShapeToScene(blocks.nextShape!){
//            self.blocks.nextShape?.moveTo(StartingColumn, row: StartingRow)
//            self.scene.movePreviewShape(self.blocks.nextShape!){
//                let nextShapes = self.blocks.newShape()
//                self.scene.startTicking()
//                self.scene.addPreviewShapeToScene(nextShapes.nextShape!){}
//            }
//        }
    
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func didTap(sender: UITapGestureRecognizer) {
        blocks.rotateShape()
    }
    
    @IBAction func ChangeShape(sender: UIButton) {

        let changingShapes = blocks.changeNextShape()
        self.scene.clearPreviewShape(changingShapes.oldShape!)
        self.scene.addPreviewShapeToScene(changingShapes.newShape!) {}

    }
    
    @IBAction func didPan(sender: UIPanGestureRecognizer) {
        let currentPoint = sender.translationInView(self.view)
        if let originalPoint = panPointReference {
            
            if abs(currentPoint.x - originalPoint.x) > (BlockSize * 0.9) {
                
                if sender.velocityInView(self.view).x > CGFloat(0) {
                    blocks.moveShapeRight()
                    panPointReference = currentPoint
                } else {
                    blocks.moveShapeLeft()
                    panPointReference = currentPoint
                }
            }
        } else if sender.state == .Began {
            panPointReference = currentPoint
        }
    }
    
    
    @IBAction func didSwipe(sender: UISwipeGestureRecognizer) {
        blocks.dropShape()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UISwipeGestureRecognizer {
            if otherGestureRecognizer is UIPanGestureRecognizer {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            if otherGestureRecognizer is UITapGestureRecognizer {
                return true
            }
        }
        return false
    }
    
    func didTick(){
        blocks.letShapeFall()
//        blocks.fallingShape?.lowerShapeByOneRow()
//        scene.redrawShape(blocks.fallingShape!, completion: {})
    }
    
    func nextShape() {
        let newShapes = blocks.newShape()
        guard let fallingShape = newShapes.fallingShape else {
            return
        }
        self.scene.addPreviewShapeToScene(newShapes.nextShape!) {}
        self.scene.movePreviewShape(fallingShape) {
            
            self.view.userInteractionEnabled = true
            self.scene.startTicking()
        }
    }
    
    func gameDidBegin(blocks: Blocks) {
        
        levelLabel.text = "\(blocks.level)"
        scoreLabel.text = "\(blocks.score)"
        scene.tickLengthMillis = TickLengthLevelOne
        
        // The following is false when restarting a new game
        if blocks.nextShape != nil && blocks.nextShape!.blocks[0].sprite == nil {
            scene.addPreviewShapeToScene(blocks.nextShape!) {
                self.nextShape()
            }
        } else {
            nextShape()
        }
    }
    
    func gameDidEnd(blocks: Blocks) {
        view.userInteractionEnabled = false
        scene.stopTicking()
        
        scene.playSound("gameover.mp3")
        scene.animateCollapsingLines(blocks.removeAllBlocks(), fallenBlocks: Array<Array<Block>>()) {
            blocks.beginGame()
        }
    }
    
    func gameDidLevelUp(blocks: Blocks) {
        
        levelLabel.text = "\(blocks.level)"
        if scene.tickLengthMillis >= 100 {
            scene.tickLengthMillis -= 100
        } else if scene.tickLengthMillis > 50 {
            scene.tickLengthMillis -= 50
        }
        scene.playSound("levelup.mp3")
        
    }
    
    func gameShapeDidDrop(swiftris: Blocks) {
        
        scene.stopTicking()
        scene.redrawShape(swiftris.fallingShape!) {
            self.blocks.letShapeFall()
        }
        scene.playSound("drop.mp3")
    }
    
    func gameShapeDidLand(blocks: Blocks) {
        scene.stopTicking()
//        nextShape()
        self.view.userInteractionEnabled = false
        
        let removedLines = blocks.removeCompletedLines()
        if removedLines.linesRemoved.count > 0 {
            self.scoreLabel.text = "\(blocks.score)"
            scene.animateCollapsingLines(removedLines.linesRemoved, fallenBlocks:removedLines.fallenBlocks) {
                
                self.gameShapeDidLand(blocks)
            }
            scene.playSound("bomb.mp3")
        } else {
            nextShape()
        }
    }
    
    func gameShapeDidMove(swiftris: Blocks) {
        scene.redrawShape(swiftris.fallingShape!) {}
    }
}
