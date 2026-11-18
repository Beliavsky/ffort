subroutine combos(n_max,m_max)
! print combinations of m_max out of n_max
! 06/01/2019 02:38 PM branched from xcombinations.f90
! 06/01/2019 02:37 PM from Rosetta Code, combinations problem https://rosettacode.org/wiki/Combinations#Fortran
integer, intent(in)  :: n_max,m_max
integer              :: icomb,nchoose
integer, allocatable :: comb(:)
logical              :: print_comb_
print_comb_ = .false.
if (allocated(comb_mat)) deallocate (comb_mat)
nchoose = choose(n_max,m_max)
! print*,"n_max, m_max, nchoose =",n_max,m_max,nchoose !! debug
allocate (comb(m_max),comb_mat(nchoose,m_max))
comb = 0
call gen(1,n_max,m_max,comb,comb_mat,zero_icomb=.true.)
if (print_comb_) then
   do icomb=1,nchoose
      write (*,*) icomb,comb_mat(icomb,:)
   end do
   write (*,*) "#comb =",nchoose
end if
end subroutine combos
!
