c
c -------------------------------------------------------------------------
c
      subroutine dumpgauge(q,aux,xlow,ylow,nvar,mitot,mjtot,mptr)
c
      implicit double precision (a-h,o-z)

      include "gauges.i"
      include "call.i"

      integer bsearch
      dimension q(mitot,mjtot,nvar), var(maxvar)
      dimension aux(mitot,mjtot,1)

c  # see if this grid contains any gauges so data can be output
c  # may turn out this should be sorted, but for now do linear search
c
c  # array is sorted according to indices in mbestorder array
c  # so do binary search to find start. Could have many same source grids
c
c     write(34,*) 'in dumpgauge with mgauges, mptr = ',mgauges,mptr
      if (mgauges.eq.0) then
         return
         endif

      istart = bsearch(mptr) 
      if (istart .lt. 1) return      !this grid not used

c     # this stuff the same for all gauges on this grid
      tgrid = rnode(timemult,mptr)
      level = node(nestlevel,mptr)
      hx    =  hxposs(level)
      hy    =  hyposs(level)

      do 10 ii = istart, mgauges
        i = mbestorder(ii)   ! gauge number
c       write(34,*) 'istart,ii,i:',istart,ii,i
        if (mptr .ne. mbestsrc(i)) go to 99  ! all done
        if (tgrid.lt.t1gauge(i) .or. tgrid.gt.t2gauge(i)) then
c          # don't output at this time for gauge i
           go to 10
           endif
c
c
c ## prepare to do bilinear interp at gauge location to get vars
c
        iindex =  int(.5 + (xgauge(i)-xlow)/hx)
        jindex =  int(.5 + (ygauge(i)-ylow)/hy)
        if ((iindex .lt. nghost .or. iindex .gt. mitot-nghost) .or.
     .      (jindex .lt. nghost .or. jindex .gt. mjtot-nghost))
     .    write(*,*)"ERROR in output of Gauge Data "
        xcent  = xlow + (iindex-.5)*hx
        ycent  = ylow + (jindex-.5)*hy
        xoff   = (xgauge(i)-xcent)/hx
        yoff   = (ygauge(i)-ycent)/hy
	if (xoff .lt. 0. .or. xoff .gt. 1. or. 
     .	    yoff .lt. 0. .or. yoff .gt. 1.) then
	       write(6,*)" BIG PROBLEM in DUMPGAUGE", i
	endif

c       ## bilinear interpolation
        do ivar = 1, nvar
           var(ivar) = (1.d0-xoff)*(1.d0-yoff)*q(iindex,jindex,ivar) 
     .             + xoff*(1.d0-yoff)*q(iindex+1,jindex,ivar)
     .             + (1.d0-xoff)*yoff*q(iindex,jindex+1,ivar) 
     .             + xoff*yoff*q(iindex+1,jindex+1,ivar)
        end do

c       # output values at gauge, along with gauge no, level, time:
!$OMP CRITICAL (gaugeio)
        write(OUTGAUGEUNIT,100)igauge(i),level,
     .                         tgrid,(var(j),j=1,nvar)
!$OMP END CRITICAL (gaugeio)

100     format(2i5,15e15.7)

 10     continue
 
 99   return
      end
c
c --------------------------------------------------------------------
c
      subroutine setbestsrc()
c
c  ## called every time grids change, to set the best source grid
c  ## to find gauge data
c
c  ## lbase is grid level that didn't change but since fine
c  ## grid may have disappeared, still have to look starting
c  ## at coarsest level 1.
c
      implicit double precision (a-h,o-z)

      include "gauges.i"
      include "call.i"
c
c ##  set source grid for each loc fromcoarsest level to finest.
c ##  that way finest src grid left and old ones overwritten
c ##  this code uses fact that grids do not overlap

c # for debugging, initialize sources to 0 then check that all set
      do i = 1, mgauges
         mbestsrc(i) = 0
      end do

 
      do 20 lev = 1, lfine  
          mptr = lstart(lev)
 5        do 10 i = 1, mgauges
            if ((xgauge(i) .ge. rnode(cornxlo,mptr)) .and.    
     .          (xgauge(i) .le. rnode(cornxhi,mptr)) .and.    
     .          (ygauge(i) .ge. rnode(cornylo,mptr)) .and.  
     .          (ygauge(i) .le. rnode(cornyhi,mptr)) )
     .      mbestsrc(i) = mptr
 10       continue

          mptr = node(levelptr, mptr)
          if (mptr .ne. 0) go to 5
 20   continue


      do i = 1, mgauges
        if (mbestsrc(i) .eq. 0) 
     .      write(6,*)"ERROR in setting grid src for gauge data",i
      end do

c
c     sort the source arrays for easy testing during integration
      call qsorti(mbestorder,mgauges,mbestsrc)

      return
      end
c
c ------------------------------------------------------------------------
c
      integer function bsearch(mptr)

      implicit double precision (a-h,o-z)
      include "gauges.i"

      bsearch = -1           ! signal if not found

      indexlo = 1
      indexhi = mgauges

 5    if (indexhi .lt. indexlo) go to 99
      mid = (indexlo + indexhi)/2

      if (mptr .gt. mbestsrc(mbestorder(mid))) then
	   indexlo = mid+1
	   go to 5
      else if (mptr .lt. mbestsrc(mbestorder(mid))) then
	   indexhi = mid-1
	   go to 5
      else    ! found the grid. find its first use in the array
	 istart = mid


 10      if (istart .gt. 1) then
            if (mbestsrc(mbestorder(istart-1)) .ne. mptr) go to 90
            istart = istart - 1
            go to 10
          endif

      endif

 90   bsearch = istart

 99   return
      end
	 
