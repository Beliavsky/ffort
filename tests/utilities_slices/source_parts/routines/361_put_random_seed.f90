subroutine put_random_seed(iadd) 
integer, allocatable :: seed(:) 
integer, intent(in), optional :: iadd
integer              :: seed_size
integer, parameter   :: nmax = 33
integer, parameter   :: iran(nmax) = &
[993639,510370,867989,459062,250118,21367,615149,928396,60451,&
375304,451750,778177,920970,929490,559068,168877,198559,&
147494,138494,709469,770595,304923,951942,108290,651756,&
326105,825471,403004,732210,245191,968430,163348,865109]
integer :: iadd_
iadd_ = default(0,iadd)
call random_seed(size=seed_size)
if (seed_size < 1) then
   return
else if (seed_size <= nmax) then
   allocate (seed(seed_size))
   seed = iran(:seed_size)
   call random_seed(put=seed+iadd_)
else
   write (*,*) "in put_random_seed, seed_size =",seed_size," need seed_size <= ",nmax,"STOPPING"
   stop
end if
end subroutine put_random_seed
!
