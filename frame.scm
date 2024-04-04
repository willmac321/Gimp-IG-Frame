(script-fu-register
            "script-fu-frame-ig-image"            ;function name
            "Instagram Frame"                     ;menu label
            "Creates a border around the smaller\ 
              width or height of the image\,
              and sets the background color and image\
              to a square IG size. Will eventually add other ratios"
                                                  ;description
            "wmac"                                ;author
            "GNU Public License"
            "April 3rd, 2024"                     ;date created
            ""                                    ;image type that the script works on
            SF-IMAGE       ""                          1
            SF-DRAWABLE    ""                          2
            SF-ADJUSTMENT  "Width of Border (px)"      '(20 1 100 1 10 0 0) ;a spin-button
            SF-ADJUSTMENT  "Max Dimension (px)"        '(1080 0 2560 1 10 0 1) ;a slider
            SF-COLOR       "Background Color"          '(0 0 0)     ;color variable
            SF-COLOR       "Frame Color"               '(255 255 255)     ;color variable
            SF-TOGGLE      "Save?"                     TRUE
)
(script-fu-menu-register "script-fu-frame-ig-image" "<Image>/Image")
(define (script-fu-frame-ig-image inImage inLayer inFrameSize inMaxDimension inBGColor inFrameColor inIsSave)
 (if (= (car (gimp-image-is-valid inImage)) FALSE)
  (gimp-message "No valid image found.") 
  (let*
    (
     (fileName (car (gimp-image-get-filename inImage)))
     (layerWidth (car (gimp-drawable-width inLayer) ) )
     (layerHeight (car (gimp-drawable-height inLayer) ) )
     (imageRatio (/ layerWidth layerHeight))
     (newPictureWidth (if (<= layerWidth layerHeight  ) 
                        (- (* inMaxDimension imageRatio ) (* 2 inFrameSize) )
                        (- inMaxDimension (* 2 inFrameSize) ) 
                      ) 
     )
     (newPictureHeight (if (< layerHeight layerWidth  ) 
                        (- (* inMaxDimension (/ 1 imageRatio) ) (* 2 inFrameSize) )
                        (- inMaxDimension (* 2 inFrameSize) ) 
                      ) 
     )
     (backgroundLayer
        (car 
          (gimp-layer-new
            inImage
            inMaxDimension
            inMaxDimension
            RGB-IMAGE
            "background"
            100
            LAYER-MODE-NORMAL
          )
        )
     )
     (frameLayer
        (car 
          (gimp-layer-new
            inImage
            (+ newPictureWidth (* inFrameSize 2))
            (+ newPictureHeight (* inFrameSize 2))
            RGB-IMAGE
            "frame"
            100
            LAYER-MODE-NORMAL
          )
        )
     )
     (offsetX)
     (offsetY)
    ) ;end of local variable def

    ;resize photo to have frame
    (gimp-layer-scale inLayer newPictureWidth newPictureHeight FALSE )

    (set! offsetX (- (/ inMaxDimension 2) (/ newPictureWidth 2)))
    (set! offsetY (- (/ inMaxDimension 2) (/ newPictureHeight 2)))
    (gimp-image-resize inImage inMaxDimension inMaxDimension offsetX offsetY)

    ; create and insert layers at offsets
    (gimp-image-insert-layer inImage backgroundLayer 0 1)
    (set! offsetX (/ (- inMaxDimension (+ newPictureWidth  (* inFrameSize 2) ) ) 2 ) )
    (set! offsetY (/ (- inMaxDimension (+ newPictureHeight (* inFrameSize 2) ) ) 2 ) )
    (gimp-image-insert-layer inImage frameLayer 0 1)
    (gimp-layer-set-offsets frameLayer offsetX offsetY)


    (gimp-context-set-background inBGColor)
    (gimp-drawable-fill backgroundLayer BACKGROUND-FILL)

    (gimp-context-set-background inFrameColor)
    (gimp-drawable-fill frameLayer BACKGROUND-FILL)

    (gimp-context-set-background '(0 0 0) )
    (gimp-context-set-foreground '(255 255 255) )
    (gimp-displays-flush)
    
    ; save out to a file in the save directory with string IG added
    (cond (
           (eq? inIsSave TRUE) 
           (
              (lambda (toSaveImage toSaveFilename) 
                  (let* 
                    (
                      (newImage (car (gimp-image-duplicate toSaveImage)))
                      (newLayer
                        (car 
                          (gimp-image-flatten
                            (car (gimp-image-duplicate toSaveImage))
                          )
                        )
                      )
                      (fileNameParts (strbreakup toSaveFilename "."))
                      (newFileName (string-append (car fileNameParts) "_IG." (cadr fileNameParts)))
                    )
                    (gimp-file-save 1 newImage newLayer newFileName (car (last (strbreakup newFileName "/") )))
                    (gimp-message (string-append "Saved as: " newFileName ))
                    (gimp-image-delete newImage)
                  )
             )
             inImage fileName
          )
        )
    )
  )
 )
)
