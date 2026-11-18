subroutine print_random_seeds(outu)
integer, intent(in), optional  :: outu
integer              :: outu_,nseeds
integer, allocatable :: seeds(:)
outu_ = default(istdout,outu)
call random_seed(size=nseeds)
allocate (seeds(nseeds))
call random_seed(get=seeds)
write (outu_,"('random_number_seeds =',1000(1x,i0))") seeds
end subroutine print_random_seeds
!
