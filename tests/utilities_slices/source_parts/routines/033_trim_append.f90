elemental function trim_append(xx,yy) result(xy)
character (len=*), intent(in) :: xx,yy
character (len=len(xx) + len(yy)) :: xy
xy = trim(xx) // yy
end function trim_append
!
