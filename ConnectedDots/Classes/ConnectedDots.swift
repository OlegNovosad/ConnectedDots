/**
 * Copyright (c) 2018 Artur Balabanskyy <balabanskyy@gmail.com>
 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

public protocol ConnectedDotsDelegate: class {
    func connectedDots(_ connectedDots: ConnectedDots, shouldSelectDotAt index:Int) -> Bool
}

@IBDesignable public class ConnectedDots: UIControl {
    
    //MARK: Constants
    public enum SelectionType {
        
        /// Select directly dot that was tapped
        case direct
        
        /// Selects previous dot if tap appeared from the left of currently selected dot.
        /// Selects next dot if tap appeared from the right of currently selected dot.
        case progressive
        
        /// Dots can't be selected by tapping on them
        case none
    }
    
    //MARK: - Inspectable Configuration Properies
    
    /// Number of dots to draw in component
    @IBInspectable public var numberOfDots: Int = 6
    
    ///Dot radius
    @IBInspectable public var dotRadius: CGFloat = 10.0
    private var dotDiameter: CGFloat {
        return dotRadius * 2.0
    }
    
    ///Default background color for dots and connection lines
    @IBInspectable public var defaultColor: UIColor = .lightGray
    
    ///Selection outline color for dot
    @IBInspectable public var selectionOutlineColor: UIColor = .darkGray
    
    ///Selection outline width
    @IBInspectable public var selectionOutlineWidth: CGFloat = 1.0
    
    ///Property that defines if text should be shown
    @IBInspectable public var showText: Bool = true
    
    ///Color fot text in dot
    @IBInspectable public var textColor: UIColor = .darkGray
    
    ///Color fot text in filled dot
    @IBInspectable public var filledDotTextColor: UIColor = .white
    
    ///Number to start generating text for dots
    @IBInspectable public var textStartingNumber: Int = 0
    
    ///Width of the line that connects two dots
    @IBInspectable public var connectorLineWidth: CGFloat = 4.0
    
    
    //MARK: - Public Configuration Properties
    
    ///Content insets
    public var insets: UIEdgeInsets = UIEdgeInsets.zero
    
    ///Font of dots text
    public var textFont = UIFont.systemFont(ofSize: 16.0)
    
    //MARK: Public Behaviour Properties
    
    ///Read-only property for selected dot index.
    ///Returns nil if no dot is selected
    public var selectedDotIndex: Int? {
        return selectedIndex
    }
    
    public var selectionType: SelectionType = .direct
    
    //MARK: - Delegate
    weak public var delegate: ConnectedDotsDelegate?
    
    //MARK: - Private properties
    
    ///Fill colors for each dot. Key in this dictionaru represents dot index
    private var dotFillColors = [Int:UIColor]()
    
    ///Selected dot index
    private var selectedIndex: Int? {
        didSet {
            setNeedsDisplay()
            self.sendActions(for: .valueChanged)
        }
    }
    
    //MARK: - Drawing
    
    public override func draw(_ rect: CGRect) {
        
        //Calculate Distance between dots
        let spaceAvailable = bounds.width - insets.left - insets.right - selectionOutlineWidth * 2.0
        let spaceBetweenDots = spaceAvailable - (dotRadius * 2) * CGFloat(numberOfDots)
        var distance: CGFloat = spaceBetweenDots
        if numberOfDots > 1 {
            distance = spaceBetweenDots / CGFloat(numberOfDots - 1)
        }
        
        let halfDistance = distance / 2.0
        
        //Set current dot frame to start position
        var currentDotRect = CGRect(x: insets.left + selectionOutlineWidth, y: (bounds.height - (dotDiameter)) / 2.0, width: dotDiameter, height: dotDiameter)
        
        //Create dots and connections
        for index in 0..<numberOfDots {
            
            //Set current color to the fill color of current dot
            var currentColor = dotFillColors[index]
            
            //If dot has no fill color - use default one
            if currentColor == nil {
                currentColor = defaultColor
            }
            
            //Fill with current color
            currentColor!.setFill()
            
            //Draw left connection line if it is not first element
            if index > 0 {
                let leftLine = UIBezierPath(rect: CGRect(x: currentDotRect.origin.x - halfDistance, y: currentDotRect.midY - connectorLineWidth / 2.0, width: halfDistance + currentDotRect.width / 2.0, height: connectorLineWidth))
                
                //If previous item has no fill color do not draw colored connection
                if dotFillColors[index - 1] == nil {
                    defaultColor.setFill()
                }
                
                leftLine.fill()
            }
            
            //Return back to current color
            currentColor!.setFill()
            
            //Draw right connection line if it is not last element
            if index < numberOfDots - 1 {
                let rightLine = UIBezierPath(rect: CGRect(x: currentDotRect.midX, y: currentDotRect.midY - connectorLineWidth / 2.0, width: halfDistance + 0.5 + currentDotRect.width / 2.0, height: connectorLineWidth))
                
                //If next item has no fill color do not draw colored connection
                if dotFillColors[index + 1] == nil {
                    defaultColor.setFill()
                }
                rightLine.fill()
            }
            
            //Return back to current color
            currentColor!.setFill()
            
            //Draw dot
            let dot = UIBezierPath(ovalIn: currentDotRect)
            dot.lineWidth = selectionOutlineWidth
            dot.fill()
            
            if let selectedIndex = selectedIndex,
                selectedIndex == index {
                selectionOutlineColor.setStroke()
                dot.stroke()
            }
            
            //Draw text if needed
            if showText {
                let color = dotFillColors[index] != nil ? filledDotTextColor : textColor
                drawText("\(index + textStartingNumber)", inDotRect: currentDotRect, color: color)
            }
            
            //Move to next dot frame
            currentDotRect.origin.x = currentDotRect.origin.x + dotDiameter + distance
        }
        
    }
    
    /// Draws text using standard NSString method. Text will be centered in rect.
    ///
    /// - Parameters:
    ///   - text: Text to draw
    ///   - rect: Dot frame to draw text inside
    ///   - rcolor: Color of text
    private func drawText(_ text:String, inDotRect rect:CGRect, color:UIColor) {
        
        let text = NSString(string:text)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center
        
        let attributes = [NSAttributedStringKey.paragraphStyle: paragraphStyle,
                          NSAttributedStringKey.foregroundColor: color,
                          NSAttributedStringKey.font: textFont]
        
        let fontHeight = text.size(withAttributes: attributes).height
        let yOffset = (rect.size.height - fontHeight) / 2.0 + rect.origin.y
        let textRect = CGRect(x: rect.origin.x, y: yOffset, width: rect.size.width, height: fontHeight)
        
        text.draw(in: textRect, withAttributes: attributes)
        
    }
    
    //MARK: - Public functions
    
    /// Sets fill color for the dot at index path
    ///
    /// - Parameters:
    ///   - color: Color to set as dot fill
    ///   - index: index of dot to apply color to
    public func setFillColor(_ color: UIColor, forDotWithIndex index:Int) {
        dotFillColors[index] = color
        setNeedsDisplay()
    }
    
    /// Removes fill color for dot and uses default color instead
    ///
    /// - Parameter index: Dot index
    public func resetDotFillColor(atIndex index:Int) {
        dotFillColors.removeValue(forKey: index)
        setNeedsDisplay()
    }
    
    /// Resets all fill colors
    public func resetFillColors() {
        dotFillColors = [Int: UIColor]()
        setNeedsDisplay()
    }
    
    /// Selects dot at index
    ///
    /// - Parameter index: Index to select dot
    public func selectDot(atIndex index: Int) {
        if delegate == nil || delegate!.connectedDots(self, shouldSelectDotAt: index) {
            if index < 0 {
                selectedIndex = 0
            }
            else if index >= numberOfDots {
                selectedIndex = numberOfDots > 0 ? numberOfDots - 1 : 0
            }
            else {
                selectedIndex = index
            }
        }
    }
    
    
    /// Removes selection from current selected dot
    public func deselectDot() {
        selectedIndex = nil
    }
    
    
    //MARK: - Tap Recognizers
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            
            //Get the tap location
            let location = touch.location(in: self)
            
            //Calculate space taken by dot
            var spaceForDot = bounds.width - insets.left - insets.right - selectionOutlineWidth * 2.0
            if numberOfDots > 0 {
                spaceForDot = spaceForDot / CGFloat(numberOfDots)
            }
            
            //Get the index of tapped dot
            let tapDotIndex = Int(location.x / spaceForDot)
            
            //Select dot
            switch selectionType {
            case .direct:
                selectDot(atIndex: tapDotIndex)
            case .progressive:
                if selectedIndex != nil {
                    if tapDotIndex > selectedIndex! {
                        selectDot(atIndex: selectedIndex! + 1)
                    }
                    else if tapDotIndex < selectedIndex! {
                        selectDot(atIndex: selectedIndex! - 1)
                    }
                }
                else {
                    selectDot(atIndex: 0)
                }
            case .none:
                break
            }
        }
    }
}
