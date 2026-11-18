function matrix_by_vector_real(xmat,xx) result(ymat)
! divide each column of xmat(:,:) by the corresponding element in xx(:)
real(kind=dp), intent(in) :: xmat(:,:),xx(:)
real(kind=dp)             :: ymat(size(xmat,1),size(xmat,2))
integer                   :: i,n2
n2 = size(xmat,2)
forall (i=1:n2) ymat(:,i) = xmat(:,i)/xx(i)
end function matrix_by_vector_real
!
! subroutine read_vec_line_real(iu,xx,nread)
! ! read words from line, where the line has the # of words followed by the words
! ! n word_1 word_2 ... word_n
! integer          , intent(in)               :: iu
! real(kind=dp)    , intent(out), allocatable :: xx(:)
! integer          , intent(out), optional    :: nread
! character (len=10000)                       :: text
! integer                                     :: ierr,nw
! read (iu,"(a)") text
! read (text,*,iostat=ierr) nw
! if (ierr /= 0) then
!    write (*,*) "in read_vec_line_real, could not read integer from '" // trim(text) // "', STOPPING"
!    stop
! end if
! if (nw > 0) then
!    allocate (xx(nw))
!    read (text,*) nw,xx
! else
!    allocate (xx(0))
! end if
! if (present(nread)) nread = size(xx)
! end subroutine read_vec_line_real
!
