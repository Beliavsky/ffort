pure function notall(ivec) result(tf)
logical, intent(in) :: ivec(:)
logical             :: tf
tf = .not. all(ivec)
end function notall
!
