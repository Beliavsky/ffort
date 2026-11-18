subroutine get_random_seeds(seeds)
integer, intent(out), allocatable :: seeds(:)
integer :: nseeds
call random_seed(size=nseeds)
allocate (seeds(nseeds))
call random_seed(get=seeds)
end subroutine get_random_seeds
!
