elemental function clip_transform(xx,xmin,xmax,transform) result(yy)
real(kind=dp), intent(in) :: xx,xmin,xmax
character (len=*), intent(in), optional :: transform
real(kind=dp)             :: yy
character (len=20) :: transform_
transform_ = default("none",transform)
if (transform_ == "sine") then
   yy = sine_transform(xx,xmin,xmax,xmin,xmax)
else if (transform_ == "half_sine") then
   yy = half_sine_transform(xx,xmin,xmax,xmin,xmax)
else
   yy = min(xmax,max(xmin,xx))
end if
end function clip_transform
!
