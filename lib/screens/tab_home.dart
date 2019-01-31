import 'dart:async';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:native_widgets/native_widgets.dart';
import 'package:scoped_model/scoped_model.dart';

import '../models/details_capsule.dart';
import '../models/details_core.dart';
import '../models/launchpad.dart';
import '../models/spacex_home.dart';
import '../widgets/cache_image.dart';
import '../widgets/list_cell.dart';
import '../widgets/separator.dart';
import 'dialog_capsule.dart';
import 'dialog_core.dart';
import 'dialog_launchpad.dart';
import 'page_launch.dart';

/// HOME TAB VIEW
/// This tab holds main information about the next launch.
/// It has a countdown widget.
class SpacexHomeTab extends StatelessWidget {
  static final Map<String, String> _menu = {
    'app.menu.settings': '/settings',
    'app.menu.about': '/about'
  };

  Future<Null> _onRefresh(SpacexHomeModel model) {
    Completer<Null> completer = Completer<Null>();
    model.refresh().then((_) => completer.complete());
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<SpacexHomeModel>(
      builder: (context, child, model) => Scaffold(
            body: RefreshIndicator(
              onRefresh: () => _onRefresh(model),
              child: CustomScrollView(
                  key: PageStorageKey('spacex_home'),
                  slivers: <Widget>[
                    SliverAppBar(
                      expandedHeight: MediaQuery.of(context).size.height * 0.3,
                      floating: false,
                      pinned: true,
                      actions: <Widget>[
                        PopupMenuButton<String>(
                          itemBuilder: (_) => _menu.keys
                              .map((string) => PopupMenuItem(
                                    value: string,
                                    child: Text(
                                      FlutterI18n.translate(context, string),
                                    ),
                                  ))
                              .toList(),
                          onSelected: (string) =>
                              Navigator.pushNamed(context, _menu[string]),
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        centerTitle: true,
                        title: Text(FlutterI18n.translate(
                          context,
                          'spacex.home.title',
                        )),
                        background: model.isLoading
                            ? NativeLoadingIndicator(center: true)
                            : Swiper(
                                itemCount: model.getPhotosCount,
                                itemBuilder: (context, index) => CacheImage(
                                      model.getPhoto(index),
                                    ),
                                autoplay: true,
                                autoplayDelay: 6000,
                                duration: 750,
                                onTap: (index) async =>
                                    await FlutterWebBrowser.openWebPage(
                                      url: model.getPhoto(index),
                                      androidToolbarColor:
                                          Theme.of(context).primaryColor,
                                    ),
                              ),
                      ),
                    ),
                    model.isLoading
                        ? SliverFillRemaining(
                            child: NativeLoadingIndicator(center: true),
                          )
                        : SliverToBoxAdapter(child: _buildBody())
                  ]),
            ),
          ),
    );
  }

  Widget _buildBody() {
    return ScopedModelDescendant<SpacexHomeModel>(
      builder: (context, child, model) => Column(children: <Widget>[
            model.launch.tentativeTime
                ? Separator.none()
                : Column(children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LaunchCountdown(model),
                    ),
                    Separator.divider(height: 0.0),
                  ]),
            ListCell(
              leading: const Icon(Icons.public, size: 42.0),
              title: model.vehicle(context),
              subtitle: model.payload(context),
              onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LaunchPage(model.launch)),
                  ),
            ),
            Separator.divider(height: 0.0, indent: 74.0),
            AbsorbPointer(
              absorbing: model.launch.tentativeTime,
              child: ListCell(
                leading: const Icon(Icons.event, size: 42.0),
                title: FlutterI18n.translate(
                  context,
                  'spacex.home.tab.date.title',
                ),
                subtitle: model.launchDate(context),
                onTap: () => Add2Calendar.addEvent2Cal(
                      Event(
                        title: model.launch.name,
                        description: model.launch.details ??
                            FlutterI18n.translate(
                              context,
                              'spacex.launch.page.no_description',
                            ),
                        location: model.launch.launchpadName,
                        startDate: model.launch.launchDate,
                        endDate: model.launch.launchDate.add(
                          Duration(minutes: 30),
                        ),
                      ),
                    ),
              ),
            ),
            Separator.divider(height: 0.0, indent: 74.0),
            ListCell(
              leading: const Icon(Icons.location_on, size: 42.0),
              title: FlutterI18n.translate(
                context,
                'spacex.home.tab.launchpad.title',
              ),
              subtitle: model.launchpad(context),
              onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScopedModel<LaunchpadModel>(
                            model: LaunchpadModel(
                              model.launch.launchpadId,
                              model.launch.launchpadName,
                            )..loadData(),
                            child: LaunchpadDialog(),
                          ),
                      fullscreenDialog: true,
                    ),
                  ),
            ),
            Separator.divider(height: 0.0, indent: 74.0),
            ListCell(
              leading: const Icon(Icons.timer, size: 42.0),
              title: FlutterI18n.translate(
                context,
                'spacex.home.tab.static_fire.title',
              ),
              subtitle: model.staticFire(context),
            ),
            Separator.divider(height: 0.0, indent: 74.0),
            model.launch.rocket.hasFairing
                ? ListCell(
                    leading: const Icon(Icons.directions_boat, size: 42.0),
                    title: FlutterI18n.translate(
                      context,
                      'spacex.home.tab.fairings.title',
                    ),
                    subtitle: model.fairings(context),
                  )
                : AbsorbPointer(
                    absorbing: model.launch.rocket.secondStage
                            .getPayload(0)
                            .capsuleSerial ==
                        null,
                    child: ListCell(
                      leading: const Icon(Icons.shopping_basket, size: 42.0),
                      title: FlutterI18n.translate(
                        context,
                        'spacex.home.tab.capsule.title',
                      ),
                      subtitle: model.capsule(context),
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScopedModel<CapsuleModel>(
                                    model: CapsuleModel(
                                      model.launch.rocket.secondStage
                                          .getPayload(0)
                                          .capsuleSerial,
                                    )..loadData(),
                                    child: CapsuleDialog(),
                                  ),
                              fullscreenDialog: true,
                            ),
                          ),
                    ),
                  ),
            Separator.divider(height: 0.0, indent: 74.0),
            AbsorbPointer(
              absorbing: model.launch.rocket.isFirstStageNull,
              child: ListCell(
                leading: const Icon(Icons.autorenew, size: 42.0),
                title: FlutterI18n.translate(
                  context,
                  'spacex.home.tab.first_stage.title',
                ),
                subtitle: model.firstStage(context),
                onTap: () => model.launch.rocket.isHeavy
                    ? showDialog(
                        context: context,
                        builder: (context) => SimpleDialog(
                              title: Text(
                                FlutterI18n.translate(
                                  context,
                                  'spacex.home.tab.first_stage.heavy_dialog.title',
                                ),
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              children: model.launch.rocket.firstStage
                                  .map((core) => AbsorbPointer(
                                        absorbing: core.id == null,
                                        child: ListCell(
                                          title: core.id != null
                                              ? FlutterI18n.translate(
                                                  context,
                                                  'spacex.dialog.vehicle.title_core',
                                                  {'serial': core.id},
                                                )
                                              : FlutterI18n.translate(
                                                  context,
                                                  'spacex.home.tab.first_stage.heavy_dialog.core_null_title',
                                                ),
                                          subtitle: model.core(context, core),
                                          onTap: () => openCorePage(
                                                context,
                                                core.id,
                                              ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                            horizontal: 24.0,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                            ),
                      )
                    : openCorePage(
                        context,
                        model.launch.rocket.getSingleCore.id,
                      ),
              ),
            )
          ]),
    );
  }

  openCorePage(BuildContext context, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScopedModel<CoreModel>(
              model: CoreModel(id)..loadData(),
              child: CoreDialog(),
            ),
        fullscreenDialog: true,
      ),
    );
  }
}
