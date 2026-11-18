function directory_sep() result(ch)
character (len=1) :: ch
ch = merge('/','\',unix())
end function directory_sep
!
