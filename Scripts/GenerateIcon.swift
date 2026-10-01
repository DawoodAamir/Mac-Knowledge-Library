import AppKit
let root=URL(fileURLWithPath:CommandLine.arguments[1])
let output=root.appendingPathComponent("Resources/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
func render(_ dimension:Int, mac:Bool)->Data {
 let bitmap=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:dimension,pixelsHigh:dimension,bitsPerSample:8,samplesPerPixel:mac ? 4 : 3,hasAlpha:mac,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
 NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:bitmap)
 let transform=NSAffineTransform();transform.scale(by:CGFloat(dimension)/1024);transform.concat()
 NSColor(calibratedRed:0.24,green:0.35,blue:0.46,alpha:1).setFill()
 if mac { NSBezierPath(roundedRect:NSRect(x:40,y:40,width:944,height:944),xRadius:200,yRadius:200).fill() }
 else { NSBezierPath(rect:NSRect(x:0,y:0,width:1024,height:1024)).fill() }
 NSColor.white.setFill();NSColor.white.setStroke();NSBezierPath.defaultLineWidth=48
 let page=NSBezierPath(roundedRect:NSRect(x:260,y:215,width:510,height:595),xRadius:35,yRadius:35);page.stroke()
 let spine=NSBezierPath();spine.move(to:NSPoint(x:350,y:215));spine.line(to:NSPoint(x:350,y:810));spine.stroke()
 for y in [405.0,535.0,665.0] { let line=NSBezierPath();line.move(to:NSPoint(x:440,y:y));line.line(to:NSPoint(x:675,y:y));line.stroke() }
 NSGraphicsContext.restoreGraphicsState()
 return bitmap.representation(using:.png,properties:[:])!
}
var entries:[[String:String]]=[]
for size in [16,32,128,256,512] { for scale in [1,2] { let name="icon-\(size)-\(scale).png";try render(size*scale,mac:true).write(to:output.appendingPathComponent(name));entries.append(["idiom":"mac","size":"\(size)x\(size)","scale":"\(scale)x","filename":name]) } }

try JSONSerialization.data(withJSONObject:["images":entries,"info":["version":1,"author":"xcode"]],options:[.prettyPrinted,.sortedKeys]).write(to:output.appendingPathComponent("Contents.json"))
