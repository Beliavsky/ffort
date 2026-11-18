function ran_uni_vec(n) result(xran)
integer, intent(in) :: n
real(kind=dp)       :: xran(n)
call random_number(xran)
end function ran_uni_vec
!
