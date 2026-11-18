elemental function and(xx,yy) result(tf)
! return .true. if xx and yy are both .true. or if xx is .true. and yy is not present
logical, intent(in), optional :: xx,yy
logical                       :: tf
tf = default(.true.,xx) .and. default(.true.,yy)
end function and
!
