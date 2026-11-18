subroutine random_number_seed(iseed)
integer, intent(in) :: iseed
integer             :: put_vec(33)
put_vec = iseed
call random_seed(put=put_vec)
end subroutine random_number_seed
!
